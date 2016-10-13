module SPV
  module Utils

    # @attr_writer Sets the current application, loads configuration
    def app=(app)
      puts "Load config"
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

    def page_path(page_id)
      File.join(repo_path, page_id)
    end
  end
end
