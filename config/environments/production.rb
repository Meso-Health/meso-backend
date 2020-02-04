require 'dragonfly/s3_data_store'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?


  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX


  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  config.lograge.enabled = true

  # The DebugExceptions middleware logs the stack trace for exceptions, but
  # it's very noisy in test and production environments. Unfortunately,
  # there is no way to control the logger in this middleware, so we have
  # to resort to a monkey-patch.
  if defined?(::ActionDispatch::DebugExceptions)
    ::ActionDispatch::DebugExceptions.class_eval do
      def logger
        nil
      end
    end
  end

  # Prepend all log lines with the following tags.
  # This is customized in config/initializers/lograge.rb, so disabled here.
  # config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "uhp_backend_#{Rails.env}"
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  # This is customized in config/application.rb, so disabled here.
  # config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = logger
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.after_initialize do
    # Enable uploading photos to aws. Avoid this for implementations where compliance is an issue.
    if ENV["AWS_PHOTO_UPLOAD_ENABLED"].present?
      Dragonfly.app.configure do
        # The CloudFront distribution fronting Dragonfly URLs is set up to
        # forward these requests to the Rails app prefixed with /dragonfly,
        # so we don't need the path prefix here
        url_path_prefix nil
        url_host ENV.fetch('AWS_CLOUDFRONT_HOST')
      end

      Dragonfly.app.use_datastore :s3,
        bucket_name: ENV.fetch('AWS_S3_BUCKET_NAME'),
        access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
        secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
        region: ENV.fetch('AWS_REGION'),
        storage_headers: {}, # override default, which grants public-read
        root_path: 'dragonfly' # all media stored under this folder in S3 bucket
    end

    # With this cost value, it will take no longer than 300ms to generate a
    # password digest. This was calibrated with BCrypt::Engine.calibrate on a
    # Heroku Standard-1X dyno on 2017-02-19.
    BCrypt::Engine.cost = 12
  end
end
