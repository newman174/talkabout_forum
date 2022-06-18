# forum_user_test.rb

require 'minitest/autorun'
require 'minitest/reporters'
require 'pry'
require 'pry-nav'
require 'date'

require_relative '../lib/forum_user'

Minitest::Reporters.use!

class ForumUserTest < Minitest::Test
  def setup
    @user = new_user
  end

  def teardown; end

  def new_user
    ForumUser.new('hamachi', 'brownies', DateTime.new(2022, 5, 8), 1)
  end

  def test_new_user
    assert_equal 'hamachi', @user.username
    assert_equal 1, @user.id
    assert_equal DateTime.new(2022, 5, 8), @user.join_date
    assert_equal 'brownies', @user.password
  end

  def test_setters
    @user.username = 'hamachi'
    assert_equal 'hamachi', @user.username

    @user.id = 2
    assert_equal 2, @user.id

    @user.join_date = DateTime.new(2022, 4, 10)
    assert_equal DateTime.new(2022, 4, 10), @user.join_date

    @user.password = 'purfect'
    assert_equal 'purfect', @user.password
  end

  def test_invalid_id
    @user.id = 'a'

    assert_equal 1, @user.id
  end

  def test_equality
    @user == new_user
  end

  def test_to_s
    @user.to_s == 'hamachi'
  end
end
