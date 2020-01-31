source 'https://rubygems.org'

ruby '2.6.4'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.7'

# Database and model layer components
gem 'pg'
gem 'paper_trail' # database versioning (tracks all changes to records)
gem 'bcrypt' # hashing and handling passwords
gem 'dragonfly', github: 'markevans/dragonfly' # image processing
gem 'activerecord-import' # speeding up bulk imports

# Background jobs
gem 'hiredis'

# API layer components
gem 'rack-cors' # provide support for Cross-Origin Resource Sharing (CORS)
gem 'roar' # JSON <-> ActiveRecord serialization and deserialization

# Web server components
gem 'puma'

# Logging and error reporting
gem 'lograge'
gem 'rollbar'

# Debugging tools (in console, etc)
gem 'awesome_print'

# Transferring funds
gem 'stripe'

# Admin panel
gem "administrate"

# Ability to use factories in production console, db:seed, etc
gem "factory_bot_rails"
gem "faker"

group :development, :test do
  # RSpec components
  gem 'rspec-rails'
  gem 'timecop'
  gem 'webmock'

  # Debugging tools
  gem 'pry' # use binding.pry to pause execution and open a debugger
  gem 'pry-byebug'
end

group :test do
  gem 'rspec_junit_formatter'
  gem 'temping', require: false # create arbitrary ActiveRecord models for use in tests (i.e. to test mixins)
  gem 'database_rewinder' # clear test db between tests (supposedly faster than database_cleaner)
  gem 'vcr' # record/replay http requests in specs
end

group :development do
  gem 'listen' # listens to file modifications and auto-reloads relevant processes
  gem 'rubocop' # linter
  gem 'spring' # faster boot-up of Rails commands
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen'
end

group :production do
  gem 'dragonfly-s3_data_store'

  # Heroku-specific gems
  gem 'rack-timeout'

  # Monitoring
  gem 'newrelic_rpm'
end
