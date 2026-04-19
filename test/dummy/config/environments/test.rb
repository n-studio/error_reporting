Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test
  config.action_dispatch.show_exceptions = :none
  config.active_support.deprecation = :stderr
  config.active_job.queue_adapter = :test
  config.active_record.maintain_test_schema = false
end
