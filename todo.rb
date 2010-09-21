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
  database[:todos] << params
  redirect '/';
end

get '/images/:image' do
  send_file(File.join('images', params[:image]))
end

__END__

## Views

@@ layout
!!! 5
%html
  %head
    %title Sinatra Todo Application
    %style
      body { background: #F2F2F2; padding-top: 65px; text-align: center; font-family: Arial, Helvetica, sans-serif; text-align: center; }
      a, a:hover { color: #185787; }
      p { margin: 0; padding: 0 0 13px 0; }
      div.clear { clear: both; }
      div.container { width: 580px; background: #FFF; position: relative; margin: 0 auto; padding: 0; }
      div.container img { float: left; }
      div.footer { color: #797c80; font-size: 12px; border-left: 1px solid #DDD; border-right: 1px solid #DDD; padding-top: 24px; padding-left: 39px; padding-right: 13px; padding-bottom: 1px; text-align: left; }
      img.img_bottom { padding: 0; margin: 0; }
      div.title { padding-top: 34px; padding-left: 39px; padding-right: 39px; text-align: left; border-left: 1px solid #DDD; border-right: 1px solid #DDD; }
      div.title h2 { font-size: 30px; color: #262626; font-weight: normal; margin: 0 0 13px 0; padding: 0; letter-spacing: 0; }
      div.title h3 { font-size: 16px; color: #3e434a; font-weight: normal; margin: 0; padding: 0 0 6px 0; line-height: 25px; }
      div.content { border-left: 1px solid #DDD; border-right: 1px solid #DDD; }
      ul#todos { padding: 0; }
      li.todo { position:relative; top:0; list-style:none; display:block; padding-left:10px; text-align:left; width:220px; height:30px; border: 1px solid #ddd; line-height:30px; margin: 0 auto -1px; }
      div.done { text-align:center; position:absolute; right:0;top:0; border-left: 1px solid #ddd; background:#eee; height:30px;margin-bottom:1px; width:30px;}
      a.delete { text-decoration:none; color:#333; }
  %body
    .container
      %img{:src =>"images/top.gif", :width => "580", :height => "8"}
      .clear
      .title
        %h2 TODO!
        %h3 
          This is a simple todo application written in Ruby using the
          %a{:href => "http://www.sinatrarb.com"} Sinatra
          framework and deployed on
          %a{:href => "http://heroku.com"} Heroku
      .content
        = yield
        %small
          Created by
          %a{:href => "http://adamzaninovich.com"} Adam Zaninovich
      .footer &nbsp;
      %img.img_bottom{:src =>"images/bottom.gif", :width => "580", :height => "8"}
      .clear
      
@@ list
%form{:action => "/", :method => "POST"}
  %input{:id => "desc", :name => "desc"}
  %input{:type =>"submit"}
%ul#todos
  - @todos.each do |todo|
    %li.todo
      = todo[:desc]
      %a.delete{:href => "/#{todo[:id]}"}
        .done
          %small x
%script document.getElementById("desc").focus()