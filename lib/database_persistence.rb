require 'bcrypt'
require 'pg'
require 'sinatra'

require_relative 'forum_content'
require_relative 'forum_user'

if Sinatra::Base.development?
  require 'pry'
  require 'pry-nav'
end

# Database storage adapter class
class DatabasePersistence
  def initialize(logger = nil)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          elsif Sinatra::Base.development?
            PG.connect(dbname: 'talkabout_forum_rb185')
          else
            PG.connect(dbname: 'test_talkabout_forum_rb185')
          end

    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger&.info "\n#{statement}: #{params}\n"
    @db.exec_params(statement, params)
  end

  # TOPICS

  # Create a new topic
  def new_topic(user_id, subject, body)
    sql = <<~SQL
      INSERT INTO topics
                  (user_id, subject, body)
           VALUES ($1, $2, $3);
    SQL

    query(sql, user_id, subject, body)

    last_topic_id
  end

  # Load a Topic object into the database
  def load_topic(topic)
    sql = <<~SQL
      INSERT INTO topics
                  (user_id, subject, body, time_posted)
           VALUES ($1, $2, $3, $4);
    SQL
    query(sql, topic.user_id, topic.subject, topic.body, topic.time_posted)
    nil
  end

  # Return a single topic with (bonus) username
  def topic(topic_id)
    return nil unless valid_id?(topic_id)

    sql = <<~SQL
         SELECT t.*,
                u.username
           FROM topics  AS t
      LEFT JOIN users   AS u ON t.user_id = u.id
          WHERE t.id = $1
    SQL

    result = query(sql, topic_id)
    tuple_to_topic(result.first)
  end

  # Return a single topic and its associated replies
  def topic_with_replies(topic_id, limit = 10, offset = 0)
    return nil unless valid_id?(topic_id)

    topic = topic(topic_id)
    topic&.replies = replies(topic_id, limit, offset)
    topic
  end

  # rubocop:disable Metrics/MethodLength

  # Get a list of all topics with some additional metadata
  def get_topics(limit = 10, offset = 0)
    sql = <<~SQL
         SELECT t.*,
                u.username,
                COUNT(r.id) AS count_replies,
                MAX(r.time_posted) AS latest_reply
           FROM topics      AS t
      LEFT JOIN replies     AS r ON t.id = r.topic_id
      LEFT JOIN users       AS u ON t.user_id = u.id
       GROUP BY t.id, username
       ORDER BY GREATEST(t.time_posted, MAX(r.time_posted)) DESC
          LIMIT $1
         OFFSET $2
    SQL

    result = query(sql, limit, offset)
    result.map { |tuple| tuple_to_topic(tuple) }
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength

  # Get a list of topics associated with a user_id
  def get_topics_by_user_id(user_id, limit = 10, offset = 0)
    sql = <<~SQL
         SELECT t.*,
                u.username  AS username,
                COUNT(r.id) AS count_replies,
                MAX(r.time_posted) AS latest_reply
           FROM topics      AS t
      LEFT JOIN replies     AS r ON t.id = r.topic_id
      LEFT JOIN users       AS u ON t.user_id = u.id
          WHERE t.user_id = $1
       GROUP BY t.id, username
       ORDER BY t.time_posted DESC
          LIMIT $2
         OFFSET $3
    SQL

    result = query(sql, user_id, limit, offset)
    result.map { |tuple| tuple_to_topic(tuple) }
  end
  # rubocop:enable Metrics/MethodLength

  # Update a topic
  def update_topic(topic_id, subject, body)
    sql = <<~SQL
      UPDATE topics
          SET subject = $1,
              body = $2
        WHERE id = $3
    SQL

    query(sql, subject, body, topic_id)
  end

  # Delete a topic
  def delete_topic(topic_id)
    sql = <<~SQL
      DELETE FROM topics where id = $1
    SQL

    query(sql, topic_id) if valid_id?(topic_id)
  end

  # Count the number of topics posted by a given user_id
  def count_topics_by_user_id(user_id)
    return nil unless valid_id?(user_id)

    sql = <<~SQL
      SELECT COUNT(id)
        FROM topics
       WHERE user_id = $1
    SQL

    query(sql, user_id).first['count'].to_i
  end

  # Count all topics in the database
  def count_topics
    sql = <<~SQL
      SELECT COUNT(id) FROM topics
    SQL

    query(sql).first['count'].to_i
  end

  # Return the id of the most recently entered topic
  def last_topic_id
    sql = <<~SQL
        SELECT id FROM topics
      ORDER BY id DESC
          LIMIT 1;
    SQL
    query(sql).first['id'].to_i
  end

  # REPLIES

  # Create a new reply
  def new_reply(user_id, topic_id, body)
    sql = <<~SQL
      INSERT INTO replies
                  (user_id, topic_id, body)
           VALUES ($1, $2, $3);
    SQL
    query(sql, user_id, topic_id, body)
    last_reply_id
  end

  # Load a Reply object into the database
  def load_reply(reply)
    sql = <<~SQL
      INSERT INTO replies
                  (user_id, topic_id, body, time_posted)
           VALUES ($1, $2, $3, $4);
    SQL
    query(sql, reply.user_id, reply.topic_id, reply.body, reply.time_posted)
    nil
  end

  # Return a single reply by its id
  def reply(reply_id)
    return nil unless valid_id?(reply_id)

    sql = <<~SQL
      SELECT * FROM replies WHERE id = $1
    SQL

    result = query(sql, reply_id)
    return nil unless result.ntuples == 1

    tuple_to_reply(result.first)
  end

  # rubocop:disable Metrics/MethodLength

  # Get the replies associated with a topic_id
  def replies(topic_id, limit = 10, offset = 0)
    return nil unless valid_id?(topic_id)

    sql = <<~SQL
       SELECT r.*,
              u.username
         FROM replies AS r
         JOIN users   AS u ON r.user_id = u.id
        WHERE r.topic_id = $1
      ORDER BY r.time_posted ASC
        LIMIT $2
       OFFSET $3
    SQL

    result = query(sql, topic_id, limit, offset)
    return [] if result.ntuples.zero?

    result.map { |tuple| tuple_to_reply(tuple) }
  end
  # rubocop:enable Metrics/MethodLength

  # Update a reply
  def update_reply(reply_id, body)
    sql = <<~SQL
      UPDATE replies
         SET body = $1
       WHERE id = $2
    SQL

    query(sql, body, reply_id)
  end

  # Delete a reply
  def delete_reply(reply_id)
    sql = <<~SQL
      DELETE FROM replies where id = $1
    SQL

    query(sql, reply_id) if valid_id?(reply_id)
  end

  # Count replies to a given topic_id
  def count_replies(topic_id)
    sql = <<~SQL
      SELECT COUNT(id)
        FROM replies
       WHERE topic_id = $1
    SQL

    query(sql, topic_id).first['count'].to_i if valid_id?(topic_id)
  end

  # Return the id of the most recently posted reply
  def last_reply_id
    sql = <<~SQL
        SELECT id FROM replies
      ORDER BY id DESC
          LIMIT 1;
    SQL
    query(sql).first['id'].to_i
  end

  # USERS

  # Add a new user
  def add_user(username, password)
    sql = <<~SQL
      INSERT INTO users
                  (username, password)
           VALUES ($1, $2)
    SQL

    hashed_pw = BCrypt::Password.create(password)
    query(sql, username, hashed_pw)
  end

  # Load a user object into the database
  def load_user(user)
    sql = <<~SQL
      INSERT INTO users
                  (username, password, join_date)
           VALUES ($1, $2, $3)
    SQL

    hashed_pw = BCrypt::Password.create(user.password)
    query(sql, user.username, hashed_pw, user.join_date)
    nil
  end

  # Get a user by their user_id
  def user(user_id)
    sql = <<~SQL
      SELECT * FROM users
       WHERE id = $1
    SQL

    result = query(sql, user_id)
    tuple_to_user(result.first)
  end

  # Get a user by their username
  def get_user_from_username(username)
    sql = <<~SQL
      SELECT * FROM users
       WHERE LOWER(username) = $1
    SQL

    result = query(sql, username.downcase)
    tuple_to_user(result.first)
  end

  # Return a hash of all usernames (keys) and passwords (values)
  def load_user_credentials
    result = query('SELECT * FROM users')

    result.each_with_object({}) do |user, cred_hsh|
      cred_hsh[user['username']] = user['password']
    end
  end

  # SEARCH

  # Count all topics matching a search query
  def count_topic_results(query)
    return 0 if query.nil? || query.strip.empty?

    sql = <<~SQL
      SELECT COUNT(DISTINCT t.id)
        FROM topics  AS t
        JOIN replies AS r ON t.id = r.topic_id
       WHERE subject ILIKE $1 OR
             t.body  ILIKE $1 OR
             r.body  ILIKE $1
    SQL

    query(sql, "%#{query}%").first['count'].to_i
  end

  # rubocop:disable Metrics/MethodLength

  # Get topics where the subject, body, username, or replies match the given query
  def search_topics(query, limit = 10, offset = 0)
    return [] if query.nil? || query.strip.empty?

    sql = <<~SQL
         SELECT t.*,
                u.username         AS username,
                COUNT(r.id)        AS count_replies,
                MAX(r.time_posted) AS latest_reply
           FROM topics  AS t
      LEFT JOIN replies AS r ON t.id = r.topic_id
      LEFT JOIN users   AS u ON t.user_id = u.id
          WHERE t.subject ILIKE $1 OR
                t.body    ILIKE $1 OR
                r.body    ILIKE $1 OR
                username  ILIKE $1
       GROUP BY t.id, username
       ORDER BY t.time_posted DESC
          LIMIT $2
         OFFSET $3
    SQL

    result = query(sql, "%#{query}%", limit, offset)
    result.map { |tuple| tuple_to_topic(tuple) }
  end
  # rubocop:enable Metrics/MethodLength

  private

  # PRIV: TUPLE CONVERSION

  # Convert a result tuple to a topic object
  def tuple_to_topic(tuple)
    return nil if tuple.nil?

    topic = Topic.new(tuple['user_id'],
                      tuple['subject'],
                      tuple['body'],
                      tuple['time_posted'],
                      tuple['id'])

    topic.username = tuple['username']
    topic.count_replies = tuple['count_replies']
    topic.latest_reply = tuple['latest_reply']
    topic
  end

  # Convert a result tuple to a reply object
  def tuple_to_reply(tuple)
    return nil if tuple.nil?

    reply = Reply.new(tuple['user_id'],
                      tuple['topic_id'],
                      tuple['body'],
                      tuple['time_posted'],
                      tuple['id'])
    reply.username = tuple['username']
    reply
  end

  # Convert a result tuple to a user object
  def tuple_to_user(tuple)
    return nil if tuple.nil?

    ForumUser.new(tuple['username'],
                  tuple['password'],
                  tuple['join_date'],
                  tuple['id'])
  end

  # PRIV: VALIDATION

  def valid_id?(id)
    id.to_i.positive?
  end
end
