%w(
  rubygems
  sinatra
  sinatra/sequel
  twitter_oauth
  haml
  yaml
).each  { |lib| require lib}

use Rack::MethodOverride
# allows for delete and put via _method in form like so:
# <form method="post" action="/destroy_it">
#  <input type="hidden" name="_method" value="delete" />
# ...

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
    String :user, :null => false
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
  @message = "Hey, check out this web app made by @thezanino! (#{ENV['APP_LINK'] || @@config['app_link']})"
end

## Routes
get '/' do # home
  redirect '/todos' if @user
  haml :home
end

get '/todos/:id' do # delete
  redirect '/' unless @user
  pass unless params[:id].to_i > 0
  @todo = Todo[params[:id]]
  if @todo.nil?
    session[:flash] = "That item was already deleted!"
    redirect '/todos'
  end
  if @todo.user === session[:username]
    @todo.delete
  else
    session[:flash] = "You can't delete an item that isn't your own!"
  end
  redirect '/todos'
end

get '/todos' do # list
  redirect '/' unless @user
  if session[:flash]
    @flash = session[:flash]
    session[:flash] = nil
  end
  @todos = Todo.filter(:user => session[:username])
  haml :list
end

post '/todos' do # create
  redirect '/' unless @user
  params["user"] = session[:username]
  database[:todos] << params unless params[:desc]==''
  @todos = Todo.filter(:user => session[:username])
  haml :list
end

get '/manage' do # list all
  halt 404 unless session[:username] === 'thezanino'
  @todos = Todo.all
  haml :manage
end

delete '/manage' do # delete
  halt 404 unless session[:username] === 'thezanino'
  pass unless params[:id].to_i > 0
  @todo = Todo[params[:id]]
  @todo.delete
  @todos = Todo.all
  haml :manage
end

get '/tweet' do # confirm tweet
  haml :tweet
end

get '/tweet/:confirm' do # send tweet or cancel
  if params[:confirm] != 'yes'
    session[:flash] = "Tweet canceled"
  else
    @twitter.update(@message)
    session[:flash] = "Tweet sent"
  end
  redirect '/todos'
end

get '/favicon.ico' do
  halt 404 unless send_file(File.join('content','favicon.ico'))
end

get '/image/*.*' do
  file,ext = params['splat']
  if ext =~ /png|jpg|jpeg|gif/
    send_file(File.join('content', file + '.' + ext))
  else
    halt 404
  end
end

get '/css/*.*' do
  file,ext = params['splat']
  if ext =~ /css/
    send_file(File.join('content', file + '.' + ext))
  else
    halt 404
  end
end

####################### Twitter Auth #######################
get '/connect' do
  # store the request tokens and send to Twitter
  puts ENV['CALLBACK_URL'] || @@config['callback_url']
  request_token = @twitter.request_token(
    :oauth_callback => ENV['CALLBACK_URL'] || @@config['callback_url']
  )
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret
  redirect request_token.authorize_url.gsub('authorize', 'authenticate')
end

get '/auth' do
  # auth URL is called by twitter after the user has accepted the application
  # this is configured on the Twitter application settings page
  
  # Exchange the request token for an access token. (fixme)
  begin
    @access_token = @twitter.authorize(
      session[:request_token],
      session[:request_token_secret],
      :oauth_verifier => params[:oauth_verifier]
    )
  rescue OAuth::Unauthorized
  end
  
  if @twitter.authorized?
      # Storing the access tokens so we don't have to go back to Twitter again
      # in this session.  In a larger app you would probably persist these details somewhere.
      session[:access_token] = @access_token.token
      session[:secret_token] = @access_token.secret
      session[:user] = true
      session[:username] = @twitter.info["screen_name"]
      session[:avatar] = @twitter.info["profile_image_url"]
      redirect '/todos'
    else
      redirect '/'
  end
end

get '/disconnect' do
  # logout
  session[:username] = nil
  session[:avatar] = nil
  session[:user] = nil
  session[:request_token] = nil
  session[:request_token_secret] = nil
  session[:access_token] = nil
  session[:secret_token] = nil
  redirect '/'
end

####################### End Twitter Auth #######################

# useful for site monitoring
get '/ping' do
  "pong"
end

__END__

## Views

@@ tweet
%h3
  %em
    = '"'+@message+'"'
  = ' - '+session[:username]
%h3 Are you sure?
%a.confirm{:href=>"/tweet/yes"}><
  yes
%a.confirm{:href=>"/tweet/no"}><
  no

@@ home
%h3
  %a{:href=>"/connect"}
    %img{:src => '/image/sign-in-with-twitter.png', :title=>"sign into this app with twitter"}

@@ layout
!!! 5
%html
  %head
    %title Sinatra Todo Application
    %link{:rel=>"icon", :href=>"/favicon.ico"}
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
          \. It's open source, and the code is at&nbsp;
          %a{:href => "http://github.com/adamzaninovich/Sinatra-Todo-List"}> GitHub
          \.
      - if @flash
        #flash
          = @flash
      = yield
      - if @user
        #user_info
          %a.username{:href => "http://twitter.com/"+session[:username], :title => "Logged in as @"+session[:username]+". Go to twitter profile."}
            %img.avatar{:src => session[:avatar]}
          %a.logout{:href => "/disconnect"}<
            Logout        
      .clear
      - if @user
        #tweet
          %a{:href=>"/tweet"} Tweet about this app
      
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

@@ manage
%table#list
  %tr.header
    %th id
    %th todo
    %th user
    %th actions
  - @todos.each do |todo|
    %tr.todo
      %td
        = todo[:id]
      %td
        = todo[:desc]
      %td
        = todo[:user]
      %td.delete
        %form{:action => "/manage", :method => "post"}
          %input{:type => "hidden", :name => "_method", :value => "delete"}
          %input{:type => "hidden", :name => "id", :value => todo[:id]}
          %input{:type => "submit", :class => "delete_button", :value => "delete"}
%a{:href => '/todos'} Back to list
