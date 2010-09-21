require 'rubygems'
require 'sinatra'

set :server, %w[thin mongrel webrick]
set :bind, 'localhost'
set :port, 4567
set :show_exceptions, true

get '/' do
  'Hello'
end
