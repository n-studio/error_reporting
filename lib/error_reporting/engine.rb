module ErrorReporting
  class Engine < ::Rails::Engine
    initializer "error_reporting.middleware", before: :load_config_initializers do |app|
      app.middleware.use ErrorReporterMiddleware
    end

    initializer "error_reporting.subscribe" do |app|
      app.config.after_initialize do
        Rails.error.subscribe(ErrorReportSubscriber.new)
      end
    end
  end
end
