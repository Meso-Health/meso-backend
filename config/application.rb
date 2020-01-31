require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module UhpBackend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # GZip our JSON responses; this has to be handled in the application server
    # and in Ruby since Heroku does not do this for you in their stack
    config.middleware.use Rack::Deflater, include: [Mime[:json].to_s]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Nairobi'

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Enable Flash, Cookies, MethodOverride for Administrate Gem
    config.middleware.use ActionDispatch::Flash
    config.session_store :cookie_store
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, config.session_options
    config.middleware.use ::Rack::MethodOverride

    # Default log_formatter for all environments; needs to be set in
    # application.rb so config/environments/*.rb can pick up this formatter
    config.log_formatter = ->(severity, timestamp, progname, msg) do
      "at=#{severity.downcase} #{msg}\n"
    end

    config.autoload_paths << "#{Rails.root}/app/models/types"
    config.autoload_paths << "#{Rails.root}/lib"

    config.before_initialize do
      # Handle exceptions with our own Rack app
      ExceptionsApp.rescue_responses.reverse_merge!(config.action_dispatch.rescue_responses)
      ExceptionsApp.rescue_responses.reverse_merge!(ActionDispatch::ExceptionWrapper.rescue_responses)
      config.exceptions_app = ExceptionsApp
    end
  end

  def self.release
    @release ||= ReleaseInfo.new(ENV)
  end
end
