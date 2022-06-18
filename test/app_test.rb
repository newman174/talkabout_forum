# app_test.rb

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/reporters'
require 'pry'
require 'pry-nav'
require 'rack/test'
require_relative '../app'

Minitest::Reporters.use!

# rubocop:disable Metrics/AbcSize

class ForumTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env['rack.session']
  end

  def login_newms
    { 'rack.session' => { username: 'newms', user_id: 1 } }
  end

  def login_hamachi
    { 'rack.session' => { username: 'hamachi', user_id: 2 } }
  end

  def setup
    system 'bundle exec rake test_resetdb'
  end

  def teardown; end

  def test_root
    get '/'
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/signin', last_response['Location']

    get '/', {}, login_newms

    assert_equal 302, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_equal 'http://example.org/topics', last_response['Location']
  end

  def test_not_found
    get '/nonexistent', {}, login_newms
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/', last_response['Location']
    assert_equal 'Page not found:  "/nonexistent"', session[:error]
  end

  # TOPIC TESTS

  # TOPIC TESTS: TOPIC ID VALIDATION

  def test_valid_topic_id
    %w[33a a 33a8 a33 33.0 33. 33_2 *].each do |bad_id|
      get "/topics/#{bad_id}", {}, login_hamachi
      assert_equal "Invalid Topic ID: #{bad_id}", session[:error]

      get "/topics/#{bad_id}/edit", {}, login_hamachi
      assert_equal "Invalid Topic ID: #{bad_id}", session[:error]

      get "/topics/#{bad_id}/delete", {}, login_hamachi
      assert_equal "Invalid Topic ID: #{bad_id}", session[:error]
    end
  end

  # TOPIC TESTS: CREATE TOPIC

  def test_new_topic_page
    get '/topics/new', {}, login_newms

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input type="text" name="subject"'
    assert_includes last_response.body, '<textarea name="body" class="body-input"'
  end

  def test_new_topic_page_cancel_button
    get '/topics?page=2', {}, login_newms
    assert_equal '/topics?page=2', session[:return_path]

    get '/topics/new'
    assert_includes last_response.body, '/topics?page=2'
  end

  # rubocop:disable Metrics/MethodLength
  def test_post_new_topic
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    assert_equal 302, last_response.status
    location = last_response['Location']
    assert_equal 'http://example.org/topics/59', location

    get location, {}, login_newms
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'hi world'
    assert_includes last_response.body, 'greetings planet'
    assert_includes last_response.body, '/topics/59/edit'

    get location, {}, login_hamachi
    assert_equal 200, last_response.status
    refute_includes last_response.body, '/topics/59/edit'
  end
  # rubocop:enable Metrics/MethodLength

  def test_post_new_topic_no_login
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/signin', last_response['Location']
    assert_equal 'You must be signed in to do that.', session[:error]
  end

  def test_post_new_topic_empty_fields
    post '/topics/new', { subject: '', body: 'greetings planet' }, login_newms
    assert_includes last_response.body, '<p>Subject field cannot be empty.'

    post '/topics/new', { subject: ' ', body: 'greetings planet' }, login_newms
    assert_includes last_response.body, '<p>Subject field cannot be empty.'

    post '/topics/new', { subject: 'hi world', body: '' }, login_newms
    assert_includes last_response.body, '<p>Body field cannot be empty.'

    post '/topics/new', { subject: 'hi world', body: ' ' }, login_newms
    assert_includes last_response.body, '<p>Body field cannot be empty.'
  end

  # TOPIC TESTS: READ TOPIC

  def test_view_topic
    get '/topics/58', {}, login_newms

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h2 class="subject">Old Forest</h2>'
    assert_includes last_response.body, 'Happiness'
  end

  def test_view_topic_logged_out
    get '/topics/26'

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/signin', last_response['Location']
    assert_equal 'You must be signed in to do that.', session[:error]
  end

  def test_user_posts_page
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    get '/users/newms', {}, login_hamachi
    assert_includes last_response.body, '<a class="subject_link" href="/topics/59">'
    assert_includes last_response.body, 'hi world'
  end

  def test_user_not_found
    get '/users/nonexistant', {}, login_hamachi
    assert_equal 'Could not find user nonexistant.', session[:error]
    assert_equal 'http://example.org/topics', last_response['Location']
  end

  def test_topic_not_found
    get '/topics/100', {}, login_newms

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/topics', last_response['Location']
    assert_equal "No topic found with ID '100'.", session[:error]
  end

  # TOPIC TESTS: UPDATE TOPIC

  def test_edit_topic_page
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    get '/topics/59/edit', {}, login_newms
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input type="text" name="subject" class="subject-input" value="hi world">'
    assert_includes last_response.body, '<textarea name="body" class="body-input">greetings planet</textarea>'
  end

  def test_edit_topic_page_cancel_button
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    11.times do |num|
      post '/topics/59/replies/new', { body: "A new reply #{num}" }
    end
    get last_response['Location']
    assert_equal '/topics/59?page=2', session[:return_path]
    get '/topics/59/edit'
    assert_includes last_response.body, '<a href="/topics/59?page=2"'
  end

  def test_edit_topic_page_unauthorized
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    get '/topics/59/edit', {}, login_hamachi
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/', last_response['Location']
    assert_equal 'You are not authorized to perform that action.', session[:error]

    refute_includes last_response.body, '<input type="text" name="subject" class="subject-input" value="hi world">'
    refute_includes last_response.body, '<textarea name="body" class="body-input">greetings planet</textarea>'
  end

  def test_edit_topic
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    post '/topics/59/edit', { subject: 'new subject', body: 'new body' }, login_newms

    get '/topics/59', {}, login_newms
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'new subject'
    assert_includes last_response.body, 'new body'
  end

  def test_edit_topic_unauthorized
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    post '/topics/59/edit', { subject: 'new subject', body: 'new body' }, login_hamachi
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/', last_response['Location']
    assert_equal 'You are not authorized to perform that action.', session[:error]

    get '/topics/59', {}, login_newms
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'hi world'
    assert_includes last_response.body, 'greetings planet'
  end

  def test_edit_topic_empty_fields
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    post '/topics/59/edit', { subject: '', body: 'new body' }, login_newms
    assert_includes last_response.body, '<p>Subject field cannot be empty.'

    post '/topics/59/edit', { subject: ' ', body: 'new body' }, login_newms
    assert_includes last_response.body, '<p>Subject field cannot be empty.'

    post '/topics/59/edit', { subject: 'new subject', body: '' }, login_newms
    assert_includes last_response.body, '<p>Body field cannot be empty.'

    post '/topics/59/edit', { subject: 'new subject', body: ' ' }, login_newms
    assert_includes last_response.body, '<p>Body field cannot be empty.'
  end

  # TOPIC TESTS: DELETE TOPIC

  def test_delete_topic
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    post '/topics/59/delete', {}, login_newms
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/topics', last_response['Location']
    assert_equal 'Topic deleted.', session[:success]

    refute_includes last_response.body, 'hi world'
  end

  def test_delete_topic_unauthorized
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    post '/topics/59/delete', {}, login_hamachi
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/', last_response['Location']
    assert_equal 'You are not authorized to perform that action.', session[:error]

    get '/topics', {}, login_newms
    assert_includes last_response.body, 'hi world'
  end

  # REPLY TESTS

  # REPLY TESTS: REPLY ID VALIDATION

    def test_valid_reply_id
      %w[81a cde12 cd 81a8 81. 81.0 a81 81_2 *].each do |bad_id|
        get "/topics/52/replies/#{bad_id}", {}, login_hamachi
        assert_equal "Invalid Reply ID: #{bad_id}", session[:error]

        get "/topics/52/replies/#{bad_id}/edit", {}, login_hamachi
        assert_equal "Invalid Reply ID: #{bad_id}", session[:error]

        post "/topics/52/replies/#{bad_id}/edit", {}, login_hamachi
        assert_equal "Invalid Reply ID: #{bad_id}", session[:error]

        post "/topics/52/replies/#{bad_id}/delete", {}, login_hamachi
        assert_equal "Invalid Reply ID: #{bad_id}", session[:error]
      end
    end

  # REPLY TESTS: CREATE / READ A REPLY

  def test_new_reply_page
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    get '/topics/59/replies/new', {}, login_newms
    assert_equal 200, last_response.status
    assert_includes last_response.body, ''
  end

  def test_new_reply_page_cancel_button
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    11.times do |num|
      post '/topics/59/replies/new', { body: "A new reply #{num}" }
    end
    get last_response['Location']
    assert_equal '/topics/59?page=2', session[:return_path]
    get '/topics/59/replies/new'
    assert_includes last_response.body, '<a href="/topics/59?page=2"'
  end

  def test_post_new_reply
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    post '/topics/59/replies/new', { body: 'A new reply' }, login_hamachi
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/topics/59?page=1', last_response['Location']

    get '/topics/59', {}, login_hamachi
    assert_includes last_response.body, 'A new reply'
    assert_includes last_response.body, '<a href="/topics/59/replies/241/edit'

    get '/topics/59', {}, login_newms
    refute_includes last_response.body, '<a href="/topics/59/replies/241/edit'
  end

  def test_post_new_reply_empty_field
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms

    post '/topics/59/replies/new', { body: '' }, login_hamachi
    assert_includes last_response.body, '<p>Body field cannot be empty.'
    post '/topics/59/replies/new', { body: ' ' }, login_hamachi
    assert_includes last_response.body, '<p>Body field cannot be empty.'
  end

  def test_replies_count
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    post '/topics/59/replies/new', { body: 'A new reply' }, login_hamachi
    post '/topics/59/replies/new', { body: 'Another new reply' }, login_newms
    post '/topics/59/replies/new', { body: 'Yet another reply' }, login_hamachi

    get '/search', { query: 'hi world' }, login_newms
    assert_match %r{div class="count-replies">\W*?3\W*?</div>}, last_response.body
  end

  # REPLY TESTS: UPDATE REPLY

  def test_edit_reply_page
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    post '/topics/59/replies/new', { body: 'A new reply' }, login_hamachi

    get '/topics/59/replies/241/edit', {}, login_hamachi
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'A new reply</textarea>'
  end

  def test_edit_reply
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    post '/topics/59/replies/new', { body: 'A new reply' }, login_hamachi

    post '/topics/59/replies/241/edit', { body: 'A new body' }
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/topics/59', last_response['Location']
    assert_equal 'Reply updated.', session[:success]

    get '/topics/59'
    assert_includes last_response.body, 'A new body'
  end

  def test_edit_reply_invalid_body
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    post '/topics/59/replies/new', { body: 'A new reply' }, login_hamachi

    post '/topics/59/replies/241/edit', { body: '' }, login_hamachi
    assert_equal 422, last_response.status
    assert_includes last_response.body, '<p>Reply body field cannot be empty. Please try again.</p>'
  end

  def test_edit_reply_page_cancel_button
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    11.times do |num|
      post '/topics/59/replies/new', { body: "A new reply #{num}" }
    end
    get last_response['Location']
    assert_equal '/topics/59?page=2', session[:return_path]
    get '/topics/59/replies/251/edit'
    assert_includes last_response.body, '<a href="/topics/59?page=2"'
  end

  def test_update_reply_unauthorized
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    post '/topics/59/replies/new', { body: 'A new reply' }, login_hamachi

    get '/topics/59/replies/241/edit', {}, login_newms
    assert_equal 302, last_response.status
    refute_includes last_response.body, 'A new reply</textarea>'
  end

  # REPLY TESTS: DELETE REPLY

  def test_delete_reply
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    11.times do |num|
      post '/topics/59/replies/new', { body: "A new reply #{num}" }
    end
    get last_response['Location']
    post '/topics/59/replies/251/delete'
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/topics/59?page=2', last_response['Location']
    assert_equal 'Reply deleted.', session[:success]

    refute_includes last_response.body, 'A new reply'
  end

  def test_delete_reply_unauthorized
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    post '/topics/59/replies/new', { body: 'A new reply' }, login_hamachi

    post '/topics/59/replies/241/delete', {}, login_newms
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/', last_response['Location']
    assert_equal 'You are not authorized to perform that action.', session[:error]

    get '/topics/59', {}, login_newms
    assert_includes last_response.body, 'A new reply'
  end

  # USER TESTS

  # USER TESTS: AUTHENTICATION

  def test_signin_page
    get '/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input name="username"'
    assert_includes last_response.body, '<input type="password" id="password" name="password"'
    assert_includes last_response.body, '<a href="/register"'
  end

  def test_signin_valid_credentials
    post '/signin', { username: 'newms', password: 'brownies' }

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/topics', last_response['Location']
    assert_equal 'Signed in as newms.', session[:success]
  end

  def test_signin_invalid_credentials
    post '/signin', { username: 'newms', password: 'password' }

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Invalid username or password. Please try again.'

    post '/signin', { username: 'newms', password: 'BROWNIES' }
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Invalid username or password. Please try again.'
  end

  def test_signin_redirect
    get '/topics?page=3'

    assert_equal 302, last_response.status
    assert_equal 'http://example.org/signin', last_response['Location']

    post '/signin', { username: 'hamachi', password: 'brownies' }
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/topics?page=3', last_response['Location']
  end

  def test_get_register_page
    get '/register'
    assert_equal 200, last_response.status
  end

  def test_register
    post '/register', { username: 'joe_guysmith', password: 'abcd1234' }
    assert_equal 302, last_response.status
    assert_equal 'Successful registration. Welcome joe_guysmith!', session[:success]
    assert_equal 'http://example.org/topics', last_response['Location']

    post '/signin', { username: 'joe_guysmith', password: 'abcd1234' }
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/topics', last_response['Location']
    assert_equal 'Signed in as joe_guysmith.', session[:success]
  end

  def test_register_invalid_username_chars
    invalid_names = ['joe guysmith', 'j*/guysmith', 'joe_guysmith#', 'jguysmith\\']

    invalid_names.each do |name|
      post '/register', { username: name, password: 'abcd1234' }
      assert_equal 422, last_response.status
      assert_includes last_response.body, 'Invalid username. Usernames may' \
      ' only contain letters, numbers, and underscores (_). Please try again.'
    end
  end

  def test_register_username_taken
    invalid_names = ['hamachi', ' hamachi', 'hamachi ', 'HAMACHI', 'hamaCHi']

    invalid_names.each do |name|
      post '/register', { username: name, password: 'abcd1234' }
      assert_equal 422, last_response.status
      assert_includes last_response.body, "Username #{name.strip} is already taken. Please try another name."
    end
  end

  def test_register_invalid_password_chars
    post '/register', { username: 'joe_guysmith', password: 'abcd 1234' }
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid password. Passwords may not contain ' \
    'whitespace. Please try again.'
  end

  def test_signout
    get '/topics', {}, login_newms
    assert_includes last_response.body, 'action="/signout"'

    post '/signout', {}, login_newms
    assert_equal 302, last_response.status
    assert_equal 'http://example.org/signin', last_response['Location']
    assert_nil session[:username]
    assert_nil session[:user_id]
    assert_equal 'You have signed out.', session[:success]
  end

  # SEARCH TESTS

  def test_search
    post '/topics/new', { subject: 'hi world', body: 'greetings planet' }, login_newms
    get '/search', { query: 'hi world' }, login_newms
    assert_includes last_response.body, 'hi world'
    assert_includes last_response.body, 'href="/topics/59"'
  end

  def test_search_no_results
    get '/search', { query: 'hi world' }, login_newms
    assert_includes last_response.body, 'No results found'
  end
end
# rubocop:enable Metrics/AbcSize
