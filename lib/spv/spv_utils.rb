require 'remote_lock'


module SPV

  module_function
  def parse_ids(ids, obligatory=true)
    raise "Page id(s) is/are obligatory." if obligatory && (ids.nil? || !ids.is_a?(String) || ids.empty?)
    ids.to_s.split(',')
  end

  module Utils

    # lock timeout after which the error will be raised.
    FILE_LOCK_TIMEOUT = 60

    # @attr_writer Sets the current application, loads configuration
    def app=(app)
      @config = nil
      @app = File.basename(app)
      raise "Missing configuration 'config/#{@app}.json'." unless File.exists?("config/#{@app}.json")
      @config = JSON.parse(File.read("config/#{@app}.json"))
    end

    # @attr_reader Gets current application name
    attr_reader :app

    # @attr_reader Gets current application config
    attr_reader :config

    def repo_path
      @config['repository']
    end

    def page_file(page_id)
      [page_path(page_id),".json"].join
    end

    # Gets the path to the page directory for the current application and configuration
    # @return path to the page directory
    def page_path(page_id)
      File.join(repo_path, page_id)
    end

    # Disables access to the file across all services in unless it's completly written or updated.
    # The method which modifies cache must comply with this when updates the page cache or page cache configurations
    # The mechanism is more than only exclusive lock on file, as the filesystem may not support exclusisve locking, and futhermore, the file may not be updated (read and write) until the process ends.
    def with_lock_on_file(path, &block)
      # $lock = RemoteLock.new(RemoteLock::Adapters::Memcached.new(memcache))
      yield
    end
  end
end
