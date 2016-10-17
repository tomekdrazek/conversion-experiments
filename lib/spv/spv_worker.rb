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
      id = entry['id']
      ver= entry['version']
      page_json = JSON.parse(File.read(page_file(id)))
      if version = page_json['versions'][ver]
        # This is time consuming operation, meanwhile the page_json may be modified!
        version['cache'] = Dir.mktmpdir do |tmp_dir|
          out = _convert_pdf_page(version['src']['input'], tmp_dir, version['src']['page'].to_i)
          _merge_channels(out, page_path(id), ver + 1)
        end
      end
      with_lock_on_file(page_file(id)) do
        page_json = JSON.parse(File.read(page_file(id))) # Re-read the json file
        page_json['versions'][ver] = version # update that particular version
        File.write(page_file(id), JSON.pretty_generate(page_json)) # Save it!
      end
    end

  end

end
