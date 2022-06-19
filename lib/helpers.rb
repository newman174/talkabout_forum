require 'sinatra'

RESULTS_LIMIT_OPTIONS = [5, 10, 50].freeze

# ROUTE HELPERS

def set_return_path
  session[:return_path] = "#{env['PATH_INFO']}?#{env['QUERY_STRING']}"
end

# ROUTE HELPERS: TOPIC IDs

def check_and_set_topic_id
  if valid_topic_id?(params[:topic_id])
    @topic_id = params[:topic_id].to_i
  else
    session[:error] = "Invalid Topic ID: #{params[:topic_id]}"
    redirect '/topics'
  end
end

def valid_topic_id?(topic_id)
  true unless topic_id.to_s.match?(/[^0-9]/)
end

# ROUTE HELPERS: REPLY IDs

def check_and_set_reply_id
  if valid_reply_id?(params[:reply_id])
    @reply_id = params[:reply_id].to_i
  else
    session[:error] = "Invalid Reply ID: #{params[:reply_id]}"
    redirect '/topics'
  end
end

def valid_reply_id?(reply_id)
  true unless reply_id.to_s.match?(/[^0-9]/)
end

# ROUTE HELPERS: AUTH

def authorization_check(authorized_user_id)
  if session[:user_id].to_i == authorized_user_id.to_i
    true
  else
    session[:error] = 'You are not authorized to perform that action.'
    logger&.warn "** FAILED AUTHORIZATION CHECK **\n" \
                 "  authorized_user_id: #{authorized_user_id}\n" \
                 "  session: #{session}\n"

    redirect '/'
  end
end

def require_signed_in_user
  return if signed_in?

  session[:error] = 'You must be signed in to do that.'
  set_return_path

  redirect '/signin'
end

def signed_in?
  session.key?(:username)
end

def signout
  session.delete(:username)
  session.delete(:user_id)
  session.delete(:return_path)
  session[:success] = 'You have signed out.'
end

def valid_credentials?(username, password)
  credentials = @storage.load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

# ROUTE HELPERS: PAGINATION

def last_page(topic_id)
  total_pages(@storage.count_replies(topic_id), session[:limit])
end

def pages_to_link(current_page, total_pages)
  return (1..total_pages).to_a if total_pages <= 5

  first_page = [current_page - 2, 1].max
  last_page = [current_page + 2, total_pages].min

  (first_page..last_page).to_a
end

def set_limit
  if params[:limit]
    session[:limit] = params[:limit].to_i
  else
    session[:limit] ||= 10
  end
end

def setup_pagination(total_items)
  @limit = session[:limit]
  @total_pages = total_pages(total_items, @limit)

  requested_page = params[:page].to_s.empty? ? 1 : params[:page]
  validate_page_request(requested_page, @total_pages)

  @current_page = requested_page.to_i
  @offset = (@current_page - 1) * @limit
  @pages_to_link = pages_to_link(@current_page, @total_pages)
end

def validate_page_request(requested_page, total_pages)
  if requested_page.to_i > total_pages
    session[:error] = "Requested page (#{requested_page}) is greater than total pages (#{total_pages}). " \
                      'You have been redirected to the last page.'
    redirect params_path({ page: total_pages })
  elsif invalid_page_num?(requested_page)
    session[:error] = "Invalid page number (#{requested_page}). " \
                      'You have been redirected to the first page.'
    redirect params_path({ page: 1 })
  end
end

def invalid_page_num?(page_num)
  page_num.to_s.match?(/[^0-9]/) || !page_num.to_i.positive?
end

# ROUTE HELPERS: INPUT VALIDATION

def error_empty(input_val, field_name)
  return unless input_val.nil? || input_val.empty?

  "#{field_name} field cannot be empty. Please try again."
end

def error_min_length(input_val, field_name, min_length)
  return unless input_val.length <= min_length

  "#{field_name} field has a minimum length of #{min_length} (you " \
  "entered #{input_val.length} chars). Please try again."
end

def error_max_length(input_val, field_name, max_length)
  return unless input_val.length > max_length

  "#{field_name} field has a maximum length of #{max_length} (you " \
  "entered #{input_val.length} chars). Please try again."
end

def error_username_exists(username)
  return if @storage.get_user_from_username(username).nil?

  "Username #{username} is already taken. Please try another name."
end

def error_invalid_username_chars(input)
  return unless input.match?(/\W/)

  'Invalid username. Usernames may only contain letters, numbers, and ' \
  'underscores (_). Please try again.'
end

def error_invalid_password_chars(input)
  return unless input.match?(/\s/)

  'Invalid password. Passwords may not contain whitespace. Please try again.'
end

def error_for_input(input, fld_name, max_len)
  error_empty(input, fld_name) || error_max_length(input, fld_name, max_len)
end

def error_username(username)
  error_for_input(username, 'Username', 30) ||
    error_invalid_username_chars(username) ||
    error_username_exists(username)
end

def error_password(password)
  error_for_input(password, 'Password', 60) ||
    error_invalid_password_chars(password)
end

# VIEW HELPERS

# rubocop:disable Metrics/BlockLength
helpers do
  def in_path?(*strings)
    strings.each { |str| return true if @request_path.include?(str) }
    false
  end

  def limit_options
    RESULTS_LIMIT_OPTIONS
  end

  def render_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end

  def params_path(params_hsh, base_path = @request_path)
    output = base_path.dup

    params_hsh[:query] = @query if @query

    if params_hsh.size.positive?
      params_a = params_hsh.map { |k, v| "#{k}=#{v}" }
      output += "?#{params_a.join('&')}"
    end
    output
  end

  def total_pages(total_items, limit)
    return 1 if [total_items, limit].any?(&:nil?)

    full_pages, remaining_items = total_items.divmod(limit)
    full_pages += 1 if full_pages.zero? || remaining_items.positive?
    full_pages
  end
end
# rubocop:enable Metrics/BlockLength
