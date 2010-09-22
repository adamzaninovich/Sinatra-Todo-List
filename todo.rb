%w(rubygems sinatra sinatra/sequel twitter_oauth haml).each  { |lib| require lib}

## Config
configure do
  set :sessions, true
  set :haml, {:format => :html5}
  set :public, 'content'
  @@config = YAML.load_file("config.yml") rescue nil || {}
end

## Database Migration
migration "create todo" do |db|
  db.create_table :todos do
    primary_key :id
    text :desc, :null => false
    # some way to distinguish users
  end
end

## Models
class Todo < Sequel::Model
end

## Set up auth
before do
  next if request.path_info =~ /ping$/
  @user = session[:user]
  @twitter = TwitterOAuth::Client.new(
    :consumer_key => ENV['CONSUMER_KEY'] || @@config['consumer_key'],
    :consumer_secret => ENV['CONSUMER_SECRET'] || @@config['consumer_secret'],
    :token => session[:access_token],
    :secret => session[:secret_token]
  )
  @rate_limit_status = @twitter.rate_limit_status
end

## Routes
get '/' do
  redirect '/todos' if @user
  haml :home
end

get '/todos/:id' do
  pass unless params[:id].to_i > 0
  @todo = Todo[params[:id]]
  @todo.delete
  redirect '/'
end

get '/todos' do
  @todos = database[:todos]
  haml :list
end

post '/todos' do
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

__END__

## Views

@@ home
%h3 You are in the home page

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
%form{:action => "/todos", :method => "POST"}
  .field
    %input{:class => "text", :id => "desc", :name => "desc"}
    %input{:class=> "button", :type =>"submit", :value=> "Add"}
%ul#todos
  - @todos.each do |todo|
    %li.todo
      = todo[:desc]
      %a.delete{:href => "/todos/#{todo[:id]}"}
        .done
          %small &#x2714;
%script document.getElementById("desc").focus()