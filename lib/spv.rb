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


    attr_accessor :async

    # @attr_reader Gets current preflight and docuemnt
    attr_reader :report
    attr_reader :queue
    attr_reader :intents
    attr_reader :displays

    # Constructor of the new Processor for the `app` application
    # @param app [String] application namespace
    def initialize(app)
      @report = []
      @intents = {}
      @displays = {}
      @queue = []
      @config = nil
      self.app=app
    end

    def output(obj = :report, force_type=nil)
      type = @config['output']
      type = force_type if (force_type)
      output = send("#{obj.to_s}")
      case type
      when 'yaml'
        puts output.to_yaml
      when 'json'
        puts output.to_json
      when 'jsonp'
        puts JSON.pretty_generate(output)
      else
        if obj == :report
          output.each do |e|
            if e['versions']
              puts "#{e['id']}: status: #{e['status']}, versions: #{e['versions'].count}"
              e['versions'].each do |v|
                puts "- #{v['version']}: status: #{v['cache'] ? "ready" : "pending"}, "
              end if e['versions']
            else
              puts "#{e['id']}"
            end
          end
        else
          output.each do |k,v|
            puts "#{k} -> #{v.inspect}"
          end
        end
      end
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
      ids.each do |page_id|
        with_lock_on_file(page_file(page_id)) do
          report_entry = if File.exists?(page_file(page_id))
            JSON.parse(File.read(page_file(page_id)))
          else
            { 'id'=> page_id, 'status'=>'deleted' }
          end
          @report << report_entry
        end
      end
    end

    def get(ids)
      ids.each do |page_id|
        with_lock_on_file(page_file(page_id)) do
          report_entry = if File.exists?(page_file(page_id))
            JSON.parse(File.read(page_file(page_id)))
          else
            { 'id'=> page_id, 'status'=>'deleted' }
          end
          @report << report_entry
        end
      end
    end

    def list(pattern)
      @report = []
      Dir.glob(page_file(pattern)).each do |f|
        page_id = File.basename(f, ".*")
        @report << { 'id'=> page_id }
      end
    end

    def process_queue(async=true)
      while entry = @queue.pop
        if async
          SPV::ConversionWorker.perform_async(entry)
        else
          SPV::ConversionWorker.new.perform(entry)
        end
      end
    end

    # Set icc profile for named intent,
    # @param name
    # @param icc path or url to icc profile to be used
    #
    def intent_set(name, icc)
      dst = intent_path(name)
      dst_icc = File.join(dst,File.basename(icc))
      FileUtils.mkdir_p(dst) # ensure directory exists
      FileUtils.cp(icc,dst_icc) # copy ICC profile to the repository
      with_lock_on_file(intent_file) do
        @intents = JSON.parse(File.read(intent_file)) if File.exists?(intent_file)
        @intents[name] = { icc: dst_icc }
        File.write(intent_file, JSON.pretty_generate(@intents))
      end
    end

    # List intents for the application
    def intent_list
      @intents = JSON.parse(File.read(intent_file)) if File.exists?(intent_file)
    end

    # Removes intent or intents by name
    # @param name name of the intent to be removed
    def intent_del(name)
      with_lock_on_file(intent_file) do
        @intents = JSON.parse(File.read(intent_file)) if File.exists?(intent_file)
        @intents.delete(name)
        File.write(intent_file, JSON.pretty_generate(@intents))
        dst = intent_path(name)
        FileUtils.rm_rf(dst) # ensure removal of the directory
      end
    end

    # Set icc profile for the display, starts background worker to process
    def display_set(name,icc)

    end

    # List displayes for the application
    def display_list(name)

    end

    # Removes display or displays by name
    # @param name name
    def display_del(name)

    end

    private

    def _update_existing(queue)
      FileUtils.mkdir_p(repo_path)  # Ensure path exists
      queue.each do |entry|
        page_id = entry['id']
        FileUtils.mkdir_p(page_path(page_id))  # Ensure path exists
        with_lock_on_file(page_file(page_id)) do
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
end
