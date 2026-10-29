class ErrorReporterMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue Exception => exception
    begin
      unless client_error?(exception)
        request = ActionDispatch::Request.new(env)
        user = env["warden"]&.user
        ErrorReport.report(exception, request: request, user: user, source: "web")
      end
    rescue => e
      Rails.logger.error("#{ErrorReporting.config.log_tag("ErrorReporterMiddleware")} #{e.message}")
    end

    raise
  end

  private

  # Exceptions Rails maps to a 4xx response via config.action_dispatch.rescue_responses
  # (UnknownFormat, RoutingError, RecordNotFound, InvalidAuthenticityToken, ...).
  def client_error?(exception)
    wrapper = ActionDispatch::ExceptionWrapper.new(nil, exception)
    wrapper.rescue_response? && wrapper.status_code < 500
  end
end
