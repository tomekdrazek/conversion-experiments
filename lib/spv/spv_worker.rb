require 'sidekiq'
require_relative 'spv_utils'
require_relative 'spv_convert'

module SPV

  # Sidekiq worker, that performs real material conversion in a background.
  class Worker
    include Sidekiq::Worker
    include SPV::Convert
    include SPV::Utils


    def perform(entry)
      self.app = entry['app']
      id = entry['id']
      ver= entry['version']
      page_json = JSON.parse(File.read(page_file(id)))
      if version = page_json['versions'][ver]
        version['cache'] = Dir.mktmpdir do |tmp_dir|
          out = _convert_pdf_page(version['src']['input'], tmp_dir, version['src']['page'].to_i)
          _merge_channels(out, page_path(id), ver + 1)
        end
      end
      File.write(page_file(id), JSON.pretty_generate(page_json))
    end

  end

end
