# rubocop:disable all
require 'faker'
require_relative './lib/forum_user'
require_relative './lib/forum_content'

SOURCES = [Faker::Movies::HitchhikersGuideToTheGalaxy,
           Faker::Movies::PrincessBride,
           Faker::Movies::LordOfTheRings,
           Faker::Movies::HarryPotter,
           Faker::TvShows::GameOfThrones,
           Faker::TvShows::HeyArnold,
           Faker::JapaneseMedia::StudioGhibli,
           Faker::JapaneseMedia::DragonBall]

FIXED_USERNAME = 'newms'

def join_date_offset
  rand(500...1000)
end

def topic_time_posted_offset
  rand(250...500)
end

def reply_time_posted_offset
  rand(0...250)
end

def generate_unique_fakes(max = nil, &block)
  Faker::UniqueGenerator.clear # Clears used values for all generators

  output = []
  begin
    loop do
      output << block.call
      return output if max && output.size == max
    end
  rescue Faker::UniqueGenerator::RetryLimitExceeded
    return output
  end
  output
end

def snake_case(str)
  str.gsub(' ', '_').gsub(/\W/, '').downcase
end

def make_users(qty)
  users = []

  names = []

  SOURCES.each do |src|
    names += generate_unique_fakes { src.unique.character } if src.respond_to?(:character)
  end

  raise StandardError, "Requested qty > limit of #{names.size}" if qty > names.size

  while users.size < qty - 1
    name = snake_case(names.shuffle!.pop)
    pw = Faker::Internet.password
    users << ForumUser.new(name, pw, DateTime.now - join_date_offset)
    # users.uniq! { |user| user.username }
  end
  users.sort_by!(&:join_date)
  users.unshift(ForumUser.new(FIXED_USERNAME, 'brownies', DateTime.now - 1001))
end

def make_topics(qty, user_id_range)
  Faker::UniqueGenerator.clear

  topics = []

  bodies = []
  subjects = []

  SOURCES.each do |src|
    bodies += generate_unique_fakes { src.unique.quote } if src.respond_to?(:quote)
    subjects += generate_unique_fakes { src.unique.location } if src.respond_to?(:location)
    subjects += generate_unique_fakes { src.unique.specie } if src.respond_to?(:specie)
    subjects += generate_unique_fakes { src.unique.starship } if src.respond_to?(:starship)
    # subjects += generate_unique_fakes { src.unique.planet } if src.respond_to?(:planet)
  end

  limit = [bodies, subjects].map(&:size).max

  raise StandardError, "Requested qty > limit of #{limit}" if qty > limit

  while topics.size < qty
    user_id = rand(user_id_range)
    subject = subjects.shuffle!.pop
    body = bodies.shuffle.sample
    time_posted = DateTime.now - topic_time_posted_offset

    topics << Topic.new(user_id, subject, body, time_posted)
    # topics.uniq! { |t| t.subject }
  end

  topics.sort_by(&:time_posted)
end

def make_replies(qty, user_id_range, topic_id_range)
  replies = []

  bodies = []

  SOURCES.each do |src|
    bodies += generate_unique_fakes { src.unique.quote } if src.respond_to?(:quote)
  end

  while replies.size < qty
    user_id = rand(user_id_range)
    body = bodies.shuffle.pop
    next if body.nil?

    topic_id = rand(topic_id_range)
    time_posted = DateTime.now - reply_time_posted_offset

    replies << Reply.new(user_id, topic_id, body, time_posted)
  end

  replies.sort_by(&:time_posted)
end

# USER_COUNT = 5
# TOPIC_COUNT = 5
# REPLY_COUNT = 5

# users = make_users(USER_COUNT)
# topics = make_topics(TOPIC_COUNT, (1..USER_COUNT))
# replies = make_replies(REPLY_COUNT, (1..USER_COUNT), (1..TOPIC_COUNT))

# [users, topics, replies].each do |arr|
#   puts
#   arr.each { |item| puts item.inspect }
#   puts
# end




# puts generate_unique_fakes { Faker::Movies::Lebowski.unique.quote }.size

# 20.times do |num|
#   name = snake_case(Faker::GreekPhilosophers.name)
#   pw = Faker::Internet.password

#   users << ForumUser.new(name, pw, DateTime.now - rand(500..1000), num + 4)
# end

# users.sort_by! do |user|
#   user.join_date
# end

# users.each do |user|
#   # puts "('#{user.username}', '#{user.password}', '#{user.join_date}')"
# end

# replies = []
# counter = 3

# users.each do |user|
#   replies << "(#{rand(1..23)}, #{rand(1..26)}, '#{Faker::Hacker.say_something_smart.gsub("'", "''")}', '#{user.join_date + 600}'),"
# end

# puts replies

# puts Faker::Games::WarhammerFantasy.creature
# puts Faker::Games::WarhammerFantasy.faction
# puts Faker::Games::WarhammerFantasy.hero
# puts Faker::Games::WarhammerFantasy.location
# puts Faker::Games::WarhammerFantasy.quote
# puts Faker::Hipster::paragraph
# puts Faker::Hipster::paragraphs
# 26.times do
#   puts ", '#{Faker::Hacker.say_something_smart.gsub("'", "''")}'),"
# end

# rubocop:enable all
