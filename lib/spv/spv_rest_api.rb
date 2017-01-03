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

      def output_json(obj)
        json @processor._map_paths(obj)
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

      def move_to_temp(file)
        logger.info file
        tmp_path = File.join(TEMP_FOLDER, "uploads", file[:filename])
        FileUtils.mkdir_p(File.dirname(tmp_path))
        FileUtils.mv(file[:tempfile].path, tmp_path)
        tmp_path
      end

      def handle_upload
        if request.content_type.downcase.include? "multipart/form-data"
          logger.info "detected multipart file upload"
          params.select { |k,v| v.is_a?(Hash) && v[:tempfile].is_a?(Tempfile) }
        else
          logger.info "detected body content file upload"
          mime_type = MIME::Types[request.content_type].first
          #if request.content_type.downcase.include?("pdf") || request.content_type.downcase.include?("image")
            # Body content may not have a file name
            filename = [params['filename'] || Dir::Tmpname.make_tmpname("upload", "tmp"), ".", mime_type.preferred_extension].join
            tmp_file = Tempfile.new(filename)
            tmp_file.write(request.body.read)
            { 'body' => { type: request.content_type, filename: filename, name: filename, tempfile: tmp_file } }
          #end
          # the body contains the file itself.
        end
      end
    end

    get '/test' do
      protected!
      output_json "Hello world"
    end

    get '/page/:id' do |id|
      protected!
      processor.get(SPV::parse_ids(id))
      output_json processor.report
    end

    # Put the exactly one page with uploaded file (selection)
    put '/page/:id' do |id|
      protected!
      uploaded = handle_upload
      file = uploaded.first[1]
      sel = params[:sel] || "1~-1"
      tmp_path = move_to_temp(file)
      processor.add(tmp_path, sel, SPV::parse_ids(id, false) )
      processor.process_queue
      output_json processor.report
    end

    delete '/page/:id' do |id|
      protected!
      processor.del(SPV::parse_ids(id, false))
      output_json processor.report
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
      output_json processor.report
    end

    # List all intents in the application
    get '/intents' do
      protected!
      processor.intent_list
      output_json processor.intents
    end

    # Gets particular intent (indicated by :id)
    get '/intent/:id' do |id|
      protected!
      processor.intent_list
      output_json processor.intents[id] || {}
    end

    # Set profile for the intent :id
    put '/intent/:id' do |id|
      protected!
      uploaded = handle_upload
      file = uploaded.first[1]
      tmp_path = move_to_temp(file)
      processor.intent_set(id, tmp_path)
      output_json processor.intents[id] || {}
    end

    # Removes profile for the particular intent
    delete '/intent/:id' do |id|
      protected!
      processor.intent_del(id)
      processor.intent_list
      output_json processor.intents[id] || {}
    end

    # List all displays in the application
    get '/displays' do
      protected!
      processor.display_list
      output_json processor.displays
    end

    # Gets particular display (indicated by :id)
    get '/display/:id' do |id|
      protected!
      processor.display_list
      output_json processor.displays[id] || {}
    end

    # Set profile for the display :id
    put '/display/:id' do |id|
      protected!
      uploaded = handle_upload
      file = uploaded.first[1]
      tmp_path = move_to_temp(file)
      processor.display_set(id, tmp_path)
      output_json processor.displays[id] || {}
    end

    # Removes profile for the particular display
    delete '/display/:id' do |id|
      protected!
      processor.display_del(id)
      processor.display_list
      output_json processor.displays[id] || {}
    end
    # start the server if ruby file executed directly
    run! if app_file == $0
  end
end
