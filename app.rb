# talkabout_forum_rb185

require 'bcrypt'
require 'encrypted_cookie'
require 'redcarpet'
require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'

require_relative './lib/database_persistence'
require_relative './lib/forum_content'
require_relative './lib/helpers'

PUBLIC_PATHS = ['/', '/signin', '/register', '/favicon.ico'].freeze
APP_NAME = 'TalkAbout'.freeze

configure do
  set :erb, escape_html: true
end

configure(:development) do
  require 'sinatra/reloader'
  require 'pry'
  require 'pry-nav'
  also_reload './lib/database_persistence.rb'
  also_reload './lib/forum_content.rb'
  also_reload './lib/forum_user.rb'
  also_reload './lib/helpers.rb'
end

configure(:production, :development) do
  use Rack::Session::EncryptedCookie, secret: '93163b7d62925e504feb9bfaa1943d637a582fc019ad6d956d55dbec7ee8c22a'
end

configure(:test) do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @app_name = APP_NAME
  @storage = DatabasePersistence.new(logger)
  @request_path = env['PATH_INFO']

  unless PUBLIC_PATHS.include?(@request_path)
    set_limit
    require_signed_in_user
  end
end

before '/topics/:topic_id*' do
  pass if params[:topic_id] == 'new'
  check_and_set_topic_id
end

before '/topics/:topic_id/replies/:reply_id*' do
  pass if params[:reply_id] == 'new'
  check_and_set_reply_id
end

after do
  @storage.disconnect
end

not_found do
  session[:error] = "Page not found:  \"#{@request_path}\""
  redirect '/'
end

get '/' do
  redirect '/topics' if signed_in?
  redirect '/signin'
end

# TOPICS

# View a list of topics
get '/topics' do
  setup_pagination(@storage.count_topics)
  @topics = @storage.get_topics(@limit, @offset)
  set_return_path
  erb :topics
end

# Get the new topic page
get '/topics/new' do
  erb :new_topic
end

# Create a new topic
post '/topics/new' do
  @subject = params[:subject]&.strip
  @body = params[:body]&.strip

  error_subj = error_for_input(@subject, 'Subject', 100)
  error_body = error_for_input(@body, 'Body', 4000)
  error = error_subj || error_body

  if error
    session[:error] = error
    erb :new_topic
  else
    topic_id = @storage.new_topic(session[:user_id], @subject, @body)
    session[:success] = 'Topic posted.'
    redirect "/topics/#{topic_id}"
  end
end

# Delete a topic
post '/topics/:topic_id/delete' do
  topic_owner_id = @storage.topic(@topic_id).user_id
  authorization_check(topic_owner_id)

  @storage.delete_topic(@topic_id)
  session[:success] = 'Topic deleted.'
  redirect '/topics'
end

# View edit topic page
get '/topics/:topic_id/edit' do
  topic_owner_id = @storage.topic(@topic_id).user_id
  authorization_check(topic_owner_id)

  @topic = @storage.topic(@topic_id)
  erb :edit_topic
end

# Edit a topic
post '/topics/:topic_id/edit' do
  topic_owner_id = @storage.topic(@topic_id).user_id
  authorization_check(topic_owner_id)

  @subject = params[:subject].strip
  @body = params[:body].strip

  error_subj = error_for_input(@subject, 'Subject', 85)
  error_body = error_for_input(@body, 'Body', 4000)
  error = error_subj || error_body

  if error
    @topic = @storage.topic(@topic_id)
    session[:error] = error
    erb :edit_topic
  else
    @storage.update_topic(@topic_id, @subject, @body)
    session[:success] = 'Topic updated.'
    redirect "/topics/#{@topic_id}"
  end
end

# View a single topic and its replies
get '/topics/:topic_id' do
  setup_pagination(@storage.count_replies(@topic_id))

  @topic = @storage.topic_with_replies(@topic_id, @limit, @offset)
  unless @topic
    session[:error] = "No topic found with ID '#{@topic_id}'."
    redirect '/topics'
  end

  set_return_path
  erb :view_topic
end

# REPLIES

# Get the new reply page
get '/topics/:topic_id/replies/new' do
  @topic = @storage.topic(@topic_id)
  erb :new_reply
end

# Reply to a topic
post '/topics/:topic_id/replies/new' do
  @body = params[:body].strip

  error = error_for_input(@body, 'Body', 4000)
  if error
    @topic = @storage.topic(@topic_id)
    session[:error] = error
    erb :new_reply
  else
    @storage.new_reply(session[:user_id], @topic_id, @body)
    redirect "/topics/#{@topic_id}?page=#{last_page(@topic_id)}"
  end
end

# Get the edit reply page
get '/topics/:topic_id/replies/:reply_id/edit' do
  reply_owner_id = @storage.reply(@reply_id)&.user_id
  authorization_check(reply_owner_id)

  @topic = @storage.topic(@topic_id)

  @reply = @storage.reply(@reply_id)
  erb :edit_reply
end

# Edit a reply
post '/topics/:topic_id/replies/:reply_id/edit' do
  reply_owner_id = @storage.reply(@reply_id)&.user_id
  authorization_check(reply_owner_id)

  @body = params[:body].strip

  error = error_for_input(@body, 'Reply body', 4000)
  if error
    @topic = @storage.topic(@topic_id)
    session[:error] = error
    @reply = @storage.reply(@reply_id)
    status 422
    erb :edit_reply
  else
    @storage.update_reply(@reply_id, @body)
    session[:success] = 'Reply updated.'
    redirect session[:return_path] || "/topics/#{@topic_id}"
  end
end

# Delete a Reply
post '/topics/:topic_id/replies/:reply_id/delete' do
  reply_owner_id = @storage.reply(@reply_id)&.user_id
  authorization_check(reply_owner_id)

  @storage.delete_reply(@reply_id)
  session[:success] = 'Reply deleted.'
  redirect session[:return_path] || "/topics/#{@topic_id}"
end

# USERS

# View the signin page
get '/signin' do
  signout if signed_in?
  erb :signin
end

# Sign in the user
post '/signin' do
  @username = params[:username].strip
  @password = params[:password].strip

  @purported_user = @storage.get_user_from_username(@username)

  if valid_credentials?(@username, @password)
    session[:username] = @username
    session[:user_id] = @purported_user.id
    session[:success] = "Signed in as #{@username}."
    return_path = session[:return_path] || '/topics'
    redirect return_path
  else
    session[:error] = 'Invalid username or password. Please try again.'
    erb :signin
  end
end

# Sign a user out
post '/signout' do
  signout
  redirect '/signin'
end

# Get the user registration page
get '/register' do
  signout if signed_in?
  erb :register
end

# Register a new user
post '/register' do
  @username = params['username'].strip
  @password = params['password'].strip

  error_username = error_username(@username)
  error_password = error_password(@password)
  error = error_username || error_password

  if error
    session[:error] = error
    status 422
    erb :register
  else
    @storage.add_user(@username, @password)
    session[:username] = @username
    session[:user_id] = @storage.get_user_from_username(@username).id
    session[:success] = "Successful registration. Welcome #{@username}!"
    redirect '/topics'
  end
end

# View a user's page
get '/users/:username' do
  @user = @storage.get_user_from_username(params[:username])

  unless @user
    session[:error] = "Could not find user #{params[:username]}."
    redirect '/topics'
  end

  total_topics = @storage.count_topics_by_user_id(@user.id)
  setup_pagination(total_topics)
  @topics = @storage.get_topics_by_user_id(@user.id, @limit, @offset)
  set_return_path

  erb :user
end

# SEARCH

# Get the search results page
get '/search' do
  @query = params[:query].strip
  count_results = @storage.count_topic_results(@query)
  setup_pagination(count_results)

  @topics = @storage.search_topics(@query, @limit, @offset)
  set_return_path

  erb :search_results
end
