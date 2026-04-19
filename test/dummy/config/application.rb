require_relative "boot"

require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)
require "error_reporting"

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.0

    config.eager_load = false
    config.secret_key_base = "dummy"
    config.active_job.queue_adapter = :test
    config.action_mailer.delivery_method = :test
    config.action_mailer.default_url_options = { host: "localhost" }
    config.filter_parameters += %i[password token secret]

    # Silence deprecation/log noise during test runs.
    config.logger = Logger.new(IO::NULL)
    config.log_level = :fatal
  end
end
