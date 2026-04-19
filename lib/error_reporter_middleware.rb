class ErrorReporterMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue Exception => exception
    begin
      request = ActionDispatch::Request.new(env)
      user = env["warden"]&.user
      ErrorReport.report(exception, request: request, user: user, source: "web")
    rescue => e
      Rails.logger.error("#{ErrorReporting.config.log_tag("ErrorReporterMiddleware")} #{e.message}")
    end

    raise
  end
end
