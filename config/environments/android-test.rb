Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = false
  config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=3600'
  }

  # Show full error reports and disable caching.
  # config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # The following two config options (`consider_all_requests_local` and
  # `action_dispatch.show_exceptions`) only affect tests that go through the
  # Rails middleware stack: namely, the request specs. In those specs, we want
  # to trigger our exception handling instead of allowing exceptions to be
  # handled by Rails' debugging middleware (ActionDispatch::DebugExceptions).

  config.consider_all_requests_local     = false # default in Rails 5.0.2
  config.action_dispatch.show_exceptions = true  # default in Rails 5.0.2

  # When debugging request specs, setting `consider_all_requests_local` back to
  # true can be helpful.

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.lograge.enabled = false

  config.after_initialize do
    Rollbar.configure do |config|
      config.enabled = false
    end

    Dragonfly.app.use_datastore :memory

    # Speed up password generation in non-production environments
    ActiveModel::SecurePassword.min_cost = true
  end
end
