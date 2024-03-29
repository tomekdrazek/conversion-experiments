require 'remote_lock'
require 'colorize'
require 'open-uri'

module SPV
  PATH_MAPS = [:intents, :displays, :repository]
  module_function
  def parse_ids(ids, obligatory=true)
    raise "Page id(s) is/are obligatory." if obligatory && (ids.nil? || !ids.is_a?(String) || ids.empty?)
    ids.to_s.split(',')
  end

  module Utils

    # lock timeout after which the error will be raised.
    @@redis = nil
    @@lock  = nil

    # @attr_writer Sets the current application, loads configuration
    def app=(app)
      @config = nil
      @@redis = @@redis || Redis.new(REDIS_CONNECTION || {})
      @app = File.basename(app)
      if File.exist?("config/apps/#{@app}.json")
        @config = _load_json("config/apps/#{@app}.json")
      elsif File.exist?("config/apps/#{@app}.yaml")
        @config = YAML.load_file("config/apps/#{@app}.yaml")
      else
        raise "Missing configuration 'config/apps/#{@app}.json|.yaml'."
      end
    end

    # @attr_reader Gets current application name
    attr_reader :app

    # @attr_reader Gets current application config
    attr_reader :config



    def repo_path(repo = :repository)
      @config[repo.to_s]
    end

    def page_file(page_id)
      [page_path(page_id),".json"].join
    end

    # Gets the path to the page directory for the current application and configuration
    # @return path to the page directory
    def page_path(page_id)
      File.join(repo_path, page_id)
    end

    def intent_path(name)
      File.join(repo_path(:intents), name)
    end

    def intent_file
      [ repo_path(:intents), ".json" ].join
    end

    def display_path(name)
      File.join(repo_path(:displays), name)
    end

    def display_file
      [ repo_path(:displays), ".json" ].join
    end
    # Disables access to the file across all services in unless it's completly written or updated.
    # The method which modifies cache must comply with this when updates the page cache or page cache configurations
    # The mechanism is more than only exclusive lock on file, as the filesystem may not support exclusisve locking, and futhermore, the file may not be updated (read and write) until the process ends.
    def with_lock_on(path, &block)
      @@lock  = @@lock || RemoteLock.new(RemoteLock::Adapters::Redis.new(@@redis))
      @@lock.synchronize(path) do
        yield
      end if @@lock
    end

    # Check if file is local or remote file system (url), if local just perform block on it, otherwise performs download to the temp folder, performs block and remove temporary files.
    # Handles http/s and ftp/s connections
    def _download_sandbox(src, &block)

      download = false
      uri = URI.parse(src)
      tmp_src = if uri.scheme.nil?
        src
      else
        download = true
        basename = File.basename(uri.path)
        FileUtils.mkdir_p(File.join(TEMP_FOLDER, "downloads"))
        tmp = File.join(TEMP_FOLDER, "downloads", basename)
        uri.open do |f|
          IO.copy_stream(f, tmp)
        end
        tmp
      end
      yield tmp_src
      if download
        FileUtils.rm tmp_src
      end
    end

    # Interfaces load_json feature, so can be easly changed to database if needed
    def _load_json(path)
      with_lock_on(path) do
        JSON.parse(File.read(path)) if File.exist?(path)
      end
    end

    # Interfaces save_json feature, so can be easly changed to database if needed
    def _save_json(path, object)
      with_lock_on(path) do
        File.write(path, JSON.pretty_generate(object))
      end
    end


    # This method retrives a duplicate of object with all paths mapped to URL-s as defined in the application config
    def _map_paths(obj)
      obj.each_with_object({}) do |(k,v),g|
        g[k] = (Hash === v) ? _map_paths(v) : ( PATH_MAPS.each {|s| v=v.gsub(config[s.to_s], config["#{s.to_s}URL"]) }; v)
      end
    end

  end
end
