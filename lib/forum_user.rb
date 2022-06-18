# forum_user.rb

require 'date'

# Forum user class
class ForumUser
  attr_accessor :username, :password
  attr_reader :id, :join_date

  def initialize(username, password,
                 join_date = DateTime.now, id = nil)
    self.username = username
    self.password = password
    self.join_date = join_date
    self.id = id
  end

  def id=(uid)
    @id = uid.to_i if valid_id?(uid)
  end

  # We can handle proper DateTime objects and parsable strings
  def join_date=(timestamp)
    timestamp = DateTime.parse(timestamp) unless timestamp.is_a? DateTime
    @join_date = timestamp
  end

  def to_s
    username
  end

  def inspect
    "#{self.class}:#{object_id}, " \
    "@username = #{@username}, " \
    "@password = #{@password}, " \
    "@join_date = #{@join_date}, " \
    "@user_id = #{@user_id}"
  end

  def ==(other)
    username.downcase == other.username.downcase
  end

  private

  def valid_id?(id)
    id.to_i.positive?
  end
end
