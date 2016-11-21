require 'sinatra/base'

module SPV
  class RestAPI < Sinatra::Application
    get '/test' do
      "Hello world"
    end

    
    # start the server if ruby file executed directly
    run! if app_file == $0
  end
end
