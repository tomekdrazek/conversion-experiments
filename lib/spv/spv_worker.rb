require 'sidekiq'
require_relative '../../config/init.rb'
require_relative 'spv_utils'
require_relative 'spv_convert'

Sidekiq.configure_server do |config|
  config.redis = SPV::REDIS_CONNECTION
end

Sidekiq.configure_client do |config|
  config.redis = SPV::REDIS_CONNECTION
end

module SPV
  class LogFormatter < Sidekiq::Logging::Pretty
    @@hostname = Socket.gethostname
    def call(severity, time, program_name, message)
      worker, id = (context||"").split(" ")
      worker = worker.nil? ? "~" : worker[0..10]
      id = id.nil? ? "~" : id[-4..-1]
      if defined?(COLOR_LOG) && COLOR_LOG
        "#{severity[0..0].to_s.colorize(severity[0..0]=="E" ? :red : :blue )}#{time.strftime('@%m-%d %H:%M:%S').light_black} #{[worker,"@", @@hostname].join.light_black}#{['(',id.to_s,')'].join.magenta} #{message.to_s}\n"
      else
        "#{severity[0..0]}@#{time.strftime('%m-%d %H:%M:%S')} #{worker}@#{@@hostname}(#{id}) : #{message.to_s}\n"
      end
    end
  end
  Sidekiq.logger.formatter = LogFormatter.new

  # Sidekiq worker, that performs real material conversion in a background.
  class ConversionWorker
    include Sidekiq::Worker
    include SPV::Convert
    include SPV::Utils

    # The worker process to perform conversion in the backgorund.
    def perform(entry)
      self.app = entry['app']
      id  = entry['id']
      ver = entry['version']
      page_json = _load_json(page_file(id))
      if version = page_json['versions'][ver]
        version['cache'] = Dir.mktmpdir do |tmp_dir|
          logger.info "Convert: #{app}/#{id}/#{ver}, src: #{version['src']['input']}"
          if File.extname(version['src']['input']).downcase==".pdf"
            out = _convert_pdf_page(version['src']['input'], tmp_dir, version['src']['page'].to_i)
          else
            out = _convert_bmp_page(version['src']['input'], tmp_dir, version['src']['page'].to_i)
          end
          _merge_channels(out, page_path(id), ver + 1)

        end
        logger.info "Thumbnail: #{app}/#{id}/#{ver}, src: #{version['src']['input']}"
        version['thb'] = _thb_pdf(version['src']['input'], page_path(id), version['src']['page'].to_i)
      end
      # This is time consuming operation, meanwhile the page_json may be modified by other page versions
      with_lock_on(page_file(id)) do
        logger.info "Update: #{app}/#{id}"
        page_json = _load_json(page_file(id))
        page_json['versions'][ver] = version # update that particular version
        _save_json(page_file(id),page_json)
      end
    end
  end

  # CalibrationWorker
  class CalibrationWorker
    include Sidekiq::Worker
    include SPV::Convert
    include SPV::Utils

    def perform(app, display, intent)
      self.app = app
      puts "Calibration builder: #{display} for #{intent}"
      # TODO: change this into path that does not use fixtures:
      src = "tests/fixtures/cmyk-64.tif"

      # update calibration file with new intent:
      with_lock_on(display_file) do
        @displays = _load_json(display_file)
        @intents = _load_json(intent_file)
        if @displays && @intents && (cur_disp = @displays[display]) && (cur_intent = @intents[intent])
          dst = File.join(display_path(display), [ intent.to_s, ".jpg"].join)
          _convert_probes(src, dst, cur_intent['icc'], cur_disp['icc'])
          cur_disp['intents'] ||= {}
          cur_disp['intents'][intent] = { 'probes' => dst }
          @displays[display] = cur_disp
        end
        _save_json(display_file, @displays)
      end
    end
  end

  # Sidekiq worker, that performs deleyed removal of files in a background - to avoid waitng
  class CleanupWorker
    include Sidekiq::Worker
    include SPV::Utils
  end


end
