ErrorReporting.configure do |config|
  # ActiveRecord class that ErrorReport belongs_to. Default: "User".
  # config.user_class_name = "User"

  # App name rendered in notification email subjects (e.g. "[MyApp production]
  # ERROR: NoMethodError"). When blank, only the Rails env is shown.
  # config.app_name = "MyApp"

  # Recipient email address for notifications. When blank, notifications
  # are silently skipped. Accepts a string or a callable.
  # config.notification_email = ENV["ERROR_REPORT_EMAIL"]

  # From address for notification emails. When blank, the From header is
  # inherited from ApplicationMailer's default.
  # config.from_address = "no-reply@example.com"

  # Optional display name for the From header. When set alongside
  # from_address, the header is rendered via email_address_with_name
  # (e.g. "Error Reporter <no-reply@example.com>").
  # config.from_name = "Error Reporter"

  # Suppress repeat notifications for the same fingerprint within this window.
  # config.email_throttle_period = 1.hour
end
