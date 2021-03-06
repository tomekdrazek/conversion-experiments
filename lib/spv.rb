# The main interface class
require_relative '../config/init.rb'
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
      self.app = app
    end

    # Check against configuration for authentication embedded inside json config of the app.
    def authorized?(key)
      if config['keys']
        config['keys'].include?(key)
      else
        false
      end
    end

    def output(obj, force_type=nil)
      type = config['output']
      type = force_type if (force_type)
      obj = _map_paths(obj) if config['mapURL']
      case type
        when 'yaml'
          puts obj.to_yaml
        when 'json'
          puts obj.to_json
        when 'jsonp'
          puts JSON.pretty_generate(obj)
        else
          puts obj.inspect
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
      _download_sandbox(src) do |tmp_src|
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
    end

    def del(ids)
      ids.each do |page_id|
        with_lock_on(page_file(page_id)) do
          report_entry = if File.exist?(page_file(page_id))
            _load_json(page_file(page_id))
          else
            { 'id'=> page_id, 'status'=>'deleted' }
          end
          @report << report_entry
        end
      end
    end

    def get(ids)
      ids.each do |page_id|
        with_lock_on(page_file(page_id)) do
          report_entry = if File.exist?(page_file(page_id))
            _load_json(page_file(page_id))
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

    def process_queue(async = ASYNC_PROCESSING)
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
    def intent_set(name, icc, async = ASYNC_PROCESSING)
      dst = intent_path(name)
      _download_sandbox(icc) do |tmp_icc|
        dst_icc = File.join(dst,File.basename(tmp_icc))
        FileUtils.mkdir_p(dst) # ensure directory exists
        FileUtils.cp(tmp_icc,dst_icc) # copy ICC profile to the repository
        with_lock_on(intent_file) do
          intent_list
          @intents[name] = { 'icc' => dst_icc }
          _save_json(intent_file, @intents)
        end
      end
      display_list # read curren display list
      @displays.each do |k,i|
        if async
          SPV::CalibrationWorker.perform_async(app, k, name)
        else
          SPV::CalibrationWorker.new.perform(app, k, name)
        end
      end
      display_list if async # reload if async
    end

    # List intents for the application
    def intent_list
      @intents = _load_json(intent_file) || {}
    end

    # Removes intent or intents by name
    # @param name name of the intent to be removed
    def intent_del(name)
      with_lock_on(intent_file) do
        intent_list
        @intents.delete(name)
        _save_json(intent_file, @intents)
        dst = intent_path(name)
        FileUtils.rm_rf(dst) # ensure removal of the directory
      end
    end

    # Set icc profile for the display, starts background worker to process
    def display_set(name, icc, async = ASYNC_PROCESSING)
      dst = display_path(name)
      _download_sandbox(icc) do |tmp_icc|
        dst_icc = File.join(dst,File.basename(tmp_icc))
        FileUtils.mkdir_p(dst) # ensure directory exists
        FileUtils.cp(tmp_icc,dst_icc) # copy ICC profile to the repository
        with_lock_on(display_file) do
          display_list
          @displays[name] = { 'icc' => dst_icc }
          _save_json(display_file, @displays)
        end
      end
      intent_list # read current intents
      @intents.each do |k,i|
        if async
          SPV::CalibrationWorker.perform_async(app, name, k)
        else
          SPV::CalibrationWorker.new.perform(app,  name, k)
        end
      end
      display_list if async # reload if async
    end

    # List displayes for the application
    def display_list
      @displays = _load_json(display_file) || {}
    end

    # Removes display or displays by name
    # @param name name
    def display_del(name)
      with_lock_on(display_file) do
        display_list
        @displays.delete(name)
        _save_json(display_file, @displays)
        dst = display_path(name)
        FileUtils.rm_rf(dst) # ensure removal of the directory
      end
    end

    private

    def _update_existing(queue)
      FileUtils.mkdir_p(repo_path)  # Ensure path exists
      queue.each do |entry|
        page_id = entry['id']
        FileUtils.mkdir_p(page_path(page_id))  # Ensure path exists
        with_lock_on(page_file(page_id)) do
          report_entry = _load_json(page_file(page_id)) || { 'id'=> page_id, 'versions'=> [ ] }
          version = report_entry['versions'].count + 1
          version_entry = entry.select { |k| k!='id' }
          version_entry['version'] = version
          report_entry['versions'] << version_entry
          _save_json(page_file(page_id),report_entry)
          @report << report_entry
          @queue  << { 'app'=>@app, 'id'=>page_id, 'version'=> version - 1 }
        end
      end
    end


  end
end
