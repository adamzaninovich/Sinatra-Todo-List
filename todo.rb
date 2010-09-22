require 'rubygems'
require 'sinatra'
require 'sinatra/sequel'
require 'haml'

## Config

set :haml, {:format => :html5}
set :public, 'images'

## Database Migration
migration "create todos" do |db|
  db.create_table :todos do
    primary_key :id
    text :desc
  end
end

## Models
class Todos < Sequel::Model
end

## Routes
get '/:id' do
  pass unless params[:id].to_i > 0
  @todo = Todos[params[:id]]
  @todo.delete
  redirect '/'
end

get '/' do
  @todos = database[:todos]
  haml :list
end

post '/' do
  database[:todos] << params unless params[:desc]==''
  redirect '/';
end

get '/image/*.*' do
  file,ext = params["splat"]
  if ext == 'png'
    send_file(File.join('content', file + '.' + ext))
  else
    halt 404
  end
end

get '/css/*.*' do
  file,ext = params["splat"]
  if ext == 'css'
    send_file(File.join('content', file + '.' + ext))
  else
    halt 404
  end
end

get '/ping' do
  "pong"
end

__END__

## Views

@@ layout
!!! 5
%html
  %head
    %title Sinatra Todo Application
    %link{:rel=>"stylesheet", :type=>"text/css", :href=>"css/main.css"}
  %body
    .container
      .clear
      .title
        %h2 Sinatra Todo!
        %h3 
          This is a simple todo application written in Ruby using the
          %a{:href => "http://www.sinatrarb.com"} Sinatra
          framework and deployed on&nbsp;
          %a{:href => "http://heroku.com"}> Heroku
          \. Created by&nbsp;
          %a{:href => "http://adamzaninovich.com"}> Adam Zaninovich
          \.
      = yield          
      .clear
      
@@ list
%form{:action => "/", :method => "POST"}
  .field
    %input{:class => "text", :id => "desc", :name => "desc"}
    %input{:class=> "button", :type =>"submit", :value=> "Add"}
%ul#todos
  - @todos.each do |todo|
    %li.todo
      = todo[:desc]
      %a.delete{:href => "/#{todo[:id]}"}
        .done
          %small &#x2714;
%script document.getElementById("desc").focus()