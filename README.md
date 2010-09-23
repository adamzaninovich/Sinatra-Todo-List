# Sinatra Todo
This is a todo list app written in [Sinatra][sinatra] with login using [twitter_oauth][twitter_oauth] by [Richard Taylor][moomerman].
## Live Demo
You can see sinatra-todo running at [sinatra-todo.heroku.com][live_demo].
## Local Setup
To run the application locally you’ll need to create a [Twitter OAuth Application][twitter_app].

Once your application is setup you will have a consumer key and consumer secret. Create config.yml in the root of the app eg.

	consumer_key: YOUR_CONSUMER_KEY
	consumer_secret: YOUR_CONSUMER_SECRET
	callback_url: YOUR_CALLBACK_URL
	app_link: LINK_TO_YOUR_APP

Install the twitter_oauth gem:

	sudo gem install twitter_oauth

Run:

	ruby todo.rb

The application should now be available at `http://localhost:4567/`

## Heroku setup

As in the local setup you will need to create a [Twitter OAuth Application][twitter_app].

All you have to do is tell Heroku about your specific configuration. Assuming you have already pushed the application to Heroku, run the following:

	heroku config:add CONSUMER_KEY=<your_consumer_key> CONSUMER_SECRET=<your_consumer_secret> CALLBACK_URL=<your_callback_url> APP_LINK=<your_heroku_link>

The application should now be running on Heroku.

[moomerman]: http://github.com/moomerman
[sinatra]: http://sinatrarb.com
[twitter_oauth]: http://github.com/moomerman/twitter_oauth
[live_demo]: http://sinatra-todo.heroku.com
[twitter_app]: http://twitter.com/oauth_clients/new "Twitter - Register an Application"