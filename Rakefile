require 'rubocop/rake_task'

RuboCop::RakeTask.new

APP_NAME = 'app'.freeze
DB_NAME = 'talkabout_forum_rb185'.freeze
TEST_DB_NAME = "test_#{DB_NAME}".freeze

desc 'Make folder structure'
task 'mkdirs' do
  dirs = %w[lib public test views]
  dirs.each do |dir|
    system "mkdir #{dir}"
  end

  public_sub_dirs = %w[images javascripts stylesheets]
  public_sub_dirs.each do |sub_dir|
    system "mkdir public/#{sub_dir}"
  end
end

desc 'Start development server'
task :start_dev do
  program_file = "#{APP_NAME}.rb"
  puts ">> Rake is running #{program_file}:\n\n"
  system "bundle exec ruby #{program_file} -o 0.0.0.0 -e development"
end

desc 'Run test files'
task :test do
  test_files = Dir.glob('./test/*_test.rb').sort.reverse
  test_files.each do |test_file|
    puts ">> Rake is running #{test_file}:\n\n"
    system "bundle exec ruby #{test_file}"
  end
end

desc 'Make config.ru'
task :make_config_ru do
  File.open('config.ru', 'w+') do |file|
    file.write(<<~CONFIG
      require './#{APP_NAME}'
      run Sinatra::Application
    CONFIG
              )
  end
end

desc 'Make Procfile'
task :make_procfile do
  File.open('Procfile', 'w+') do |file|
    file.write(
      'web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e $' \
      '{RACK_ENV:-development}'
    )
  end
end

desc 'Create App Database'
task :createdb do
  sh "createdb #{DB_NAME}"
end

desc 'Drop App Database'
task dropdb: './data/schema.sql' do
  sh "dropdb --if-exists #{DB_NAME}"
end

desc 'Load Database Schema'
task load_schema: './data/schema.sql' do
  sh "psql -d #{DB_NAME} < ./data/schema.sql"
end

desc 'Load Sample Data'
task load_data: './data/sample_data.sql' do
  sh "psql -d #{DB_NAME} < ./data/sample_data.sql"
end

desc 'Connect to Database in Console'
task :connect_db do
  sh "psql -d #{DB_NAME}"
end

desc 'Reset the Database'
task resetdb: %i[dropdb createdb load_schema load_data]

desc 'Create Test Database'
task :test_createdb do
  sh "createdb #{TEST_DB_NAME}", verbose: false
end

desc 'Drop Test Database'
task test_dropdb: './data/schema.sql' do
  sh "dropdb --if-exists #{TEST_DB_NAME}", verbose: false
end

desc 'Load Test Database Schema'
task test_load_schema: './data/schema.sql' do
  sh "psql --quiet -d #{TEST_DB_NAME} < ./data/schema.sql", verbose: false
end

desc 'Load Test Sample Data'
task test_load_data: './data/sample_data.sql' do
  sh "psql --quiet -d #{TEST_DB_NAME} < ./data/sample_data.sql", verbose: false
end

desc 'Reset the Test Database'
task test_resetdb: %i[test_dropdb test_createdb test_load_schema test_load_data]

desc 'Generate a new secret'
task :generate_secret do
  puts "> Generating a new 256-bit AES secret:\n\n"
  sh 'ruby -rsecurerandom -e "puts SecureRandom.hex(32)"', verbose: false
  puts
end
