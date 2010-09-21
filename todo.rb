%w(rubygems sinatra sinatra/sequel haml).each do |f|
  require f
end

## Config
set :haml, {:format => :html5}

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

__END__

## Views

@@ layout
!!! 5
%html
  %body
    = yield

@@ list
%h2 TODO!
%form{:action => "/", :method => "POST"}
  %input{:id => "desc", :name => "desc"}
  %input{:type =>"submit"}
%ul#todos
  - @todos.each do |todo|
    %li.todo
      = todo[:desc]
      %a{:href => "/#{todo[:id]}"}
        %small done
%script document.getElementById("desc").focus()