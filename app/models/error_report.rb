class ErrorReport < ActiveRecord::Base
  belongs_to :user, class_name: ErrorReporting.config.user_class_name, optional: true

  validates :error_class, presence: true
  validates :fingerprint, presence: true
  validates :severity, inclusion: { in: %w[error warning info] }
  validates :source, inclusion: { in: %w[web job manual] }

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }

  def resolved?
    resolved_at.present?
  end

  def resolve!
    update!(resolved_at: Time.current)
  end

  def unresolve!
    update!(resolved_at: nil)
  end

  def self.report(exception, request: nil, user: nil, severity: "error", source: "manual", context: {})
    attrs = {
      error_class: exception.class.name,
      message: exception.message.truncate(10_000),
      backtrace: clean_backtrace(exception).join("\n"),
      fingerprint: generate_fingerprint(exception),
      severity: severity,
      source: source,
      context: context
    }

    if request
      attrs.merge!(
        request_method: request.request_method,
        request_url: request.original_url.truncate(2000),
        request_params: filtered_params(request),
        request_headers: safe_headers(request),
        ip_address: request.remote_ip
      )
    end

    attrs[:user_id] = user.id if user

    report = create!(attrs)
    send_notification(report)
    report
  rescue => e
    Rails.logger.error("#{ErrorReporting.config.log_tag("ErrorReport")} Failed to save error report: #{e.message}")
    nil
  end

  def self.generate_fingerprint(exception)
    first_app_line = clean_backtrace(exception).find { |line| line.start_with?("app/") } || ""
    Digest::SHA256.hexdigest("#{exception.class.name}:#{first_app_line}")
  end

  def self.clean_backtrace(exception)
    return [] unless exception.backtrace

    Rails.backtrace_cleaner.clean(exception.backtrace)
  end

  def self.filtered_params(request)
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filter.filter(request.parameters.except("controller", "action"))
  end

  def self.safe_headers(request)
    {
      "User-Agent" => request.user_agent,
      "Accept" => request.headers["Accept"],
      "Referer" => request.referer,
      "Content-Type" => request.content_type
    }.compact
  end

  def self.send_notification(report)
    return if recently_notified?(report.fingerprint)

    ErrorReportMailer.error_occurred(report).deliver_later
  end

  def self.recently_notified?(fingerprint)
    where(fingerprint: fingerprint)
      .where(created_at: ErrorReporting.config.email_throttle_period.ago..)
      .where.not(id: where(fingerprint: fingerprint).order(created_at: :desc).select(:id).limit(1))
      .exists?
  end

  private_class_method :clean_backtrace, :filtered_params, :safe_headers, :send_notification, :recently_notified?
end
