class ErrorReportSubscriber
  # Unhandled request errors are already reported by ErrorReporterMiddleware,
  # which also captures the request and user.
  IGNORED_SOURCES = %w[application.action_dispatch].freeze

  def report(error, handled:, severity:, context: {}, source: nil)
    return if IGNORED_SOURCES.include?(source)

    ErrorReport.report(
      error,
      severity: severity.to_s,
      source: source&.start_with?("application.active_job") ? "job" : "web",
      context: context.except(:request, :user).transform_values(&:to_s)
    )
  end
end
