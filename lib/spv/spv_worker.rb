require 'sidekiq'
require_relative 'spv_utils'
require_relative 'spv_convert'

module SPV

  # Sidekiq worker, that performs real material conversion in a background.
  class ConversionWorker
    include Sidekiq::Worker
    include SPV::Convert
    include SPV::Utils

    # The worker process to perform conversion in the backgorund.
    def perform(entry)
      logger.debug "Processing: #{entry}"
      self.app = entry['app']
      id  = entry['id']
      ver = entry['version']
      page_json = _load_json(page_file(id))
      if version = page_json['versions'][ver]
        version['cache'] = Dir.mktmpdir do |tmp_dir|
          out = _convert_pdf_page(version['src']['input'], tmp_dir, version['src']['page'].to_i)
          _merge_channels(out, page_path(id), ver + 1)
        end
        version['thb'] = _thb_pdf(version['src']['input'], page_path(id), version['src']['page'].to_i)
      end
      # This is time consuming operation, meanwhile the page_json may be modified by other page versions
      with_lock_on_file(page_file(id)) do
        page_json = _load_json(page_file(id))
        page_json['versions'][ver] = version # update that particular version
        File.write(page_file(id), JSON.pretty_generate(page_json)) # Save it!
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
      with_lock_on_file(display_file) do
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
