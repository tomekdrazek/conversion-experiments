require 'remote_lock'
require 'colorize'

module SPV

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
      # Load global application settings to connect to redis/remote_lock
      raise "Missing configuration 'config/config.yml'." unless File.exists?("config/config.yml")
      @settings = YAML.load(File.read("config/config.yml"))
      @@redis = @@redis || Redis.new(@settings['redis'] || {})
      # Local application specific settings
      @app = File.basename(app)
      raise "Missing configuration 'config/#{@app}.json'." unless File.exists?("config/#{@app}.json")
      @config = _load_json("config/#{@app}.json")
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

    # Interfaces load_json feature, so can be easly changed to database if needed
    def _load_json(path)
      with_lock_on(path) do
        JSON.parse(File.read(path)) if File.exists?(path)
      end
    end

    # Interfaces save_json feature, so can be easly changed to database if needed
    def _save_json(path, object)
      with_lock_on(path) do
        File.write(path, JSON.pretty_generate(object))
      end
    end
  end
end
