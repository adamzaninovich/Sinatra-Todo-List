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

get '/content/:image' do
  send_file(File.join('content', params[:image]))
end

__END__

## Views

@@ layout
!!! 5
%html
  %head
    %title Sinatra Todo Application
    %link{:rel=>"stylesheet", :type=>"text/css", :href=>"content/main.css"}
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
          \. Created by
          %a{:href => "http://adamzaninovich.com"} Adam Zaninovich
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
          %small x
%script document.getElementById("desc").focus()