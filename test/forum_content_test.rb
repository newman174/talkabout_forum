# forum_content_test.rb

require 'minitest/autorun'
require 'minitest/reporters'
require 'pry'
require 'pry-nav'
require 'date'

require_relative '../lib/forum_content'
require_relative '../lib/forum_user'

Minitest::Reporters.use!

class ForumUserTest < Minitest::Test
  def setup
    @user = new_user
    @topic = new_topic
    @reply = new_reply
  end

  def teardown; end

  def new_user
    ForumUser.new('hamachi', 'brownies', DateTime.new(2022, 5, 8), 1)
  end

  def new_topic
    Topic.new(1, 'test subject', "test body p1\n p2", DateTime.new(2022, 5, 8, 10, 0, 0), 2)
  end

  def new_reply
    Reply.new(1, 2, 'test reply body', DateTime.new(2022, 5, 8, 10, 30, 0), 3)
  end

  def test_new_topic
    assert_equal 1, @topic.user_id
    assert_equal 'test subject', @topic.subject
    assert_equal "test body p1\n p2", @topic.body
    assert_equal DateTime.new(2022, 5, 8, 10, 0, 0), @topic.time_posted
    assert_equal 2, @topic.id
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def test_topic_setters
    @topic.subject = 'new subject'
    assert_equal 'new subject', @topic.subject

    @topic.body = 'new body'
    assert_equal 'new body', @topic.body

    now = DateTime.now
    @topic.time_posted = now
    assert_equal now, @topic.time_posted

    @topic.id = 10
    assert_equal 10, @topic.id

    @topic.replies << @reply
    assert_equal [@reply], @topic.replies

    @topic.count_replies = 2
    assert_equal 2, @topic.count_replies

    @topic.username = 'hamachi'
    assert_equal 'hamachi', @topic.username
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def test_latest_reply
    @topic.latest_reply = @reply.time_posted

    assert_equal @reply.time_posted, @topic.latest_reply
  end

  def test_parse_join_date
    @topic.time_posted = 'May 8, 2022 11:00 AM'
    assert_equal DateTime.new(2022, 5, 8, 11, 0, 0), @topic.time_posted
  end

  def test_invalid_id
    @topic.id = 'a'
    assert_equal 2, @topic.id
  end

  def test_strftime
    assert_equal 'May 08, 2022 10:00 AM', @topic.strftime
  end

  def test_str_time_distance
    @topic.time_posted = DateTime.now
    assert_equal 'Less than a minute', @topic.str_time_distance
  end

  def test_str_dist_latest_activity
    now = DateTime.now

    @topic.time_posted = now - 1
    assert_equal '1 day', @topic.str_dist_latest_activity

    @topic.latest_reply = now
    assert_equal 'Less than a minute', @topic.str_dist_latest_activity
  end

  def test_new_reply
    assert_equal 1, @reply.user_id
    assert_equal 2, @reply.topic_id
    assert_equal 'test reply body', @reply.body
    assert_equal DateTime.new(2022, 5, 8, 10, 30, 0), @reply.time_posted
    assert_equal 3, @reply.id
  end

  def test_set_topic_id
    @reply.topic_id = 4
    assert_equal 4, @reply.topic_id
  end

  def test_set_invalid_topic_id
    @reply.topic_id = 'a'
    assert_equal 2, @reply.topic_id
  end
end
