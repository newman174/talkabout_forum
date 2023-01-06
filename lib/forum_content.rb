require 'action_view'
require 'date'

# Parent class for topics and replies
class ForumContent
  include ActionView::Helpers::DateHelper

  attr_accessor :username, :body
  attr_reader :user_id, :time_posted, :id

  def initialize(user_id, body, time_posted = DateTime.now, id = nil)
    self.user_id = user_id
    self.body = body
    self.time_posted = time_posted
    self.id = id
  end

  def id=(content_id)
    @id = content_id.to_i if valid_id?(content_id)
  end

  def user_id=(uid)
    @user_id = uid.to_i if valid_id?(uid)
  end

  # We can handle proper DateTime objects and parsable strings
  def time_posted=(timestamp)
    timestamp = DateTime.parse(timestamp) unless timestamp.is_a? DateTime
    @time_posted = timestamp
  end

  def strftime(format_string = nil)
    default_format = '%b %d, %Y %I:%M %p'
    format_string ||= default_format

    @time_posted.strftime(format_string)
  end

  def str_time_distance
    distance_of_time_in_words(Time.now, @time_posted).capitalize
  end

  def to_h
    {
      id: id,
      body: body,
      username: username,
      user_id: user_id,
      time_posted: time_posted,
    }
  end

  def to_s
    body
  end

  def inspect
    "#{self.class}:#{object_id}, " \
    "@id = #{@id}, " \
    "@user_id = #{@user_id}, " \
    "@body = #{@body}, " \
    "@time_posted = #{@time_posted}, " \
    "@username = #{@username}"
  end

  def ==(other)
    body == other.body && user_id == other.user_id
  end

  private

  def valid_id?(id)
    id.to_i.positive?
  end
end

# Topics have standard metadata, a subject, and a body
class Topic < ForumContent
  attr_accessor :subject, :replies, :count_replies
  attr_reader :latest_reply

  def initialize(user_id, subject, body, time_posted = DateTime.now, id = nil)
    super(user_id, body, time_posted, id)
    self.subject = subject
    self.replies = []
  end

  def str_dist_latest_activity
    latest_activity = @time_posted
    latest_activity = [@time_posted, @latest_reply].max if @latest_reply
    distance_of_time_in_words(Time.now, latest_activity).capitalize
  end

  # rubocop:disable Style/ParenthesesAroundCondition
  def latest_reply=(timestamp)
    timestamp = DateTime.parse(timestamp) if (timestamp && !timestamp.is_a?(DateTime))
    @latest_reply = timestamp
  end
  # rubocop:enable Style/ParenthesesAroundCondition

  def inspect
    super + ', ' \
    "@subject = #{@subject}, " \
    "@replies = #{@replies}, " \
    "@count_replies = #{@count_replies}, " \
    "@latest_reply = #{@latest_reply}, "
  end

  def to_h
    {
      **super,
      subject: subject,
      replies: replies.map(&:to_h),
      count_replies: count_replies,
      latest_reply: latest_reply,
      str_time_ago: str_time_distance,
      str_latest_activity: str_dist_latest_activity
    }
  end
end

# Replies to topics have standard metadata and a body
class Reply < ForumContent
  attr_reader :topic_id

  def initialize(user_id, topic_id, body, time_posted = DateTime.now, id = nil)
    super(user_id, body, time_posted, id)
    self.topic_id = topic_id
  end

  def topic_id=(t_id)
    @topic_id = t_id if valid_id?(t_id)
  end

  def inspect
    super + ", @topic_id = #{@topic_id}"
  end

  def to_h
    {
      **super,
      topic_id: topic_id
    }
  end
end
