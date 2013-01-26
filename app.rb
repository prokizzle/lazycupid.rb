require 'sinatra/base'
require './Session'
require './AutoRoller'
require './DataManager'
require './lookup'
require './Session'
require './Output'

class App < Sinatra::Base

    set :variable,"value"

    get '/' do
        haml :index
    end
end
