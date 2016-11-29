require 'sinatra/base'
require "sinatra/json"
require 'mime/types'

require_relative '../spv'

module SPV
  class RestAPI < Sinatra::Application
    use Rack::Logger

    helpers do
      def logger
        request.logger
      end

      def protected!
        return if authorized?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        if @auth.provided? && @auth.basic? && @auth.credentials
          username, password = @auth.credentials
          @processor = SPV::Processor.new(username)
          @processor.authorized?(password)
        else
          false
        end
      end

      def processor
        @processor
      end

      def handle_upload
        if request.content_type.downcase.include? "multipart/form-data"
          logger.info "detected multipart file upload"
          params.select { |k,v| v.is_a?(Hash) && v[:tempfile].is_a?(Tempfile) }
        else
          logger.info "detected body content file upload"
          mime_type = MIME::Types[request.content_type].first
          if request.content_type.downcase.include?("pdf") || request.content_type.downcase.include?("image")
            # Body content may not have a file name
            filename = [params['filename'] || Dir::Tmpname.make_tmpname("upload", "tmp"), ".", mime_type.preferred_extension].join
            tmp_file = Tempfile.new(filename)
            tmp_file.write(request.body.read)
            { 'body' => { type: request.content_type, filename: filename, name: filename, tempfile: tmp_file } }
          end
          # the body contains the file itself.
        end
      end
    end

    # use Rack::Auth::Basic, "Restricted Area" do |username, password|
    #   begin
    #     @@processor = SPV::Processor.new(username)
    #     @@processor.authorized?(password)
    #   rescue
    #     false
    #   end
    # end

    get '/test' do
      protected!
      json "Hello world"
    end

    get '/page/:id' do |id|
      protected!
      processor.get(SPV::parse_ids(id))
      json processor.report
    end


    put '/page/:id' do |id|
      protected!
      uploaded = handle_upload
      file = uploaded.first[1]
      logger.info file
      sel = params[:sel] || "1~-1"
      tmp_path = File.join(processor.settings['tmp'], "uploads", file[:filename])
      FileUtils.mkdir_p(File.dirname(tmp_path))
      FileUtils.mv(file[:tempfile].path, tmp_path)
      processor.add(tmp_path, sel, SPV::parse_ids(id, false) )
      processor.process_queue
      json processor.report
    end

    delete '/page/:id' do |id|

    end

    put '/pages' do
      # p = SPV::Processor.new(app)
      # raise "No source document specified" if args[0].nil?
      # p.add( args[0], options.sel, SPV::parse_ids(options.ids, false) )
      # p.process_queue
      # p.output(p.report, $type)
    end

    get '/pages' do
      protected!
      processor.list(params['pattern'] || "*")
      json processor.report
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
  end
end
