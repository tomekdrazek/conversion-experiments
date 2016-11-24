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
          logger.info "detected multipart"
          logger.info params.inspect
          params.select { |k,v| v.is_a?(Hash) && v[:tempfile].is_a?(Tempfile) }
        else

          logger.info params.inspect
          logger.info "detected body content"
          mime_type = MIME::Type[request.content_type].first

          if request.content_type.downcase.include? "pdf"
            # Body content may not have a file name
            filename = [params['filename'] || Dir::Tmpname.make_tmpname("upload", "tmp"), mime_type.preferred_extension].join
            tmp_file = Tempfile.new(filename)
            tmp_file.write(request.body.read)
            { 'body' => { type: request.content_type, name: filename, tempfile: tmp_file } }
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
      "Hello world"
    end

    get '/page/:id' do |id|
      # @@processor.get(SPV::parse_ids(id))
      # json @@processor.report
      # {}.to_json
    end


    put '/page/:id' do |id|
      logger.info "detected file upload"
      logger.info request.inspect
      uploaded = handle_upload
      json uploaded
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
