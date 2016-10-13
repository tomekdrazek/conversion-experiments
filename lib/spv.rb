# The main interface class
require_relative 'spv/spv_convert'
require_relative 'spv/spv_worker'
require_relative 'spv/spv_utils'
require 'json'

module SPV

  # Processor instance is responsible for control a single document analysis and conversion.
  # this class is used internally by the command line utility and web-services to
  class Processor
    include SPV::Convert
    include SPV::Utils

    # @attr_reader Gets current preflight and docuemnt
    attr_reader :report

    attr_accessor :async

    attr_reader :queue

    # Constructor of the new Processor for the `app` application
    # @param app [String] application namespace
    def initialize(app)
      @report = []
      @queue = []
      @config = nil
      @async = false
      self.app=app
    end


    # Adds a new version of the pages to the particular page ids
    # @param src [String] path to to a source document
    # @param sel [String] page selection expression
    # @param ids [Array]  assigned ids, if nil the ids will be generated automatically, obligatory to submit new version of the page.
    # The process will start in the background if worker is present.
    # Returns an object with pages description and ids associations
    # that can be easly converted to JSON
    def add(src, sel=nil, ids=nil)
      # TODO: if src is URL, download it first.
      tmp_src = src
      sel = "1~-1" if sel.nil?
      # Preflight local version of source:
      queue = if File.extname(tmp_src)==".pdf"
        _check_pdf(tmp_src)
      else
        _check_bmp(tmp_src) # TODO: not implemented
      end
      queue = _apply_sel(queue,sel,ids)
      _update_existing(queue)
    end

    def del(ids)

    end

    def get(ids)

    end

    def process_queue
      while entry = @queue.pop
        if async
          SPV::Worker.perform_async(entry)
        else
          SPV::Worker.new.perform(entry)
        end
      end
    end

    private

    def _update_existing(queue)
      FileUtils.mkdir_p(repo_path)  # Ensure path exists
      queue.each do |entry|
        page_id = entry['id']
        FileUtils.mkdir_p(page_path(page_id))  # Ensure path exists
        report_entry = if File.exists?(page_file(page_id))
          JSON.parse(File.read(page_file(page_id)))
        else
          { 'id'=> page_id, 'versions'=> [ ] }
        end
        version = report_entry['versions'].count + 1
        version_entry = entry.select { |k| k!='id' }
        version_entry['version'] = version
        report_entry['versions'] << version_entry
        File.write(page_file(page_id), JSON.pretty_generate(report_entry))
        @report << report_entry
        @queue << { 'app'=>@app, 'id'=>page_id, 'version'=> version-1 }
      end
    end



  end
end
