class ErrorReportMailer < ApplicationMailer
  def error_occurred(error_report)
    @error_report = error_report
    recipient = ErrorReporting.config.resolved_notification_email
    return if recipient.blank?

    app_name = ErrorReporting.config.resolved_app_name
    subject_prefix = app_name.present? ? "#{app_name} #{Rails.env}" : Rails.env.to_s

    headers = {
      to: recipient,
      subject: "[#{subject_prefix}] #{@error_report.severity.upcase}: #{@error_report.error_class}"
    }
    from_address = ErrorReporting.config.resolved_from_address
    if from_address.present?
      headers[:from] = email_address_with_name(from_address, ErrorReporting.config.resolved_from_name)
    end

    mail(headers)
  end
end
