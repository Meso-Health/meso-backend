require 'dragonfly'

Dragonfly.app.configure do
  plugin :imagemagick

  url_format "/media/:job-:sha.:ext"
  url_path_prefix "/dragonfly" # Dragonfly app is mounted under this in routes.rb
  secret Rails.application.secrets.secret_key_base!
  dragonfly_url nil

  # Prevent generating URLs to the original media
  define_url do |app, job, opts|
    app.server.url_for(job, opts) unless job.step_types == [:fetch]
  end

  # Force datastore to be defined per environment in config/environments/*.rb
  datastore nil
end

logger = ActiveSupport::Logger.new(STDOUT)
logger.level = Logger::INFO
Dragonfly.logger = logger

# Don't mount the Dragonfly middleware, as we manually mount the Dragonfly app
# in Rails routes under the url_path_prefix above. This allows us to isolate
# the Dragonfly app to a subdirectory and without access all Rails requests.
# Rails.application.middleware.use Dragonfly::Middleware

# Add model functionality
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend Dragonfly::Model
  ActiveRecord::Base.extend Dragonfly::Model::Validations
end
