class ErrorReportSubscriber
  def report(error, handled:, severity:, context: {}, source: nil)
    ErrorReport.report(
      error,
      severity: severity.to_s,
      source: source&.start_with?("application.active_job") ? "job" : "web",
      context: context.except(:request, :user).transform_values(&:to_s)
    )
  end
end
