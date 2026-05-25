require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Serve static files
  config.public_file_server.enabled = true

  # Assets
  config.assets.compile = false
  config.assets.digest = true

  # Active Storage
  config.active_storage.service = :cloudinary

  # Force SSL
  config.force_ssl = true

  # Logging
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_tags = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Mailer
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "myblogapp-x2xs.onrender.com" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              "smtp.gmail.com",
    port:                 587,
    domain:               "gmail.com",
    user_name:            ENV["GMAIL_USERNAME"],
    password:             ENV["GMAIL_APP_PASSWORD"],
    authentication:       "plain",
    enable_starttls_auto: true
  }

  # I18n
  config.i18n.fallbacks = true

  # Misc
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end