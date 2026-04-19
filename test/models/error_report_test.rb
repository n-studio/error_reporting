require "test_helper"

class ErrorReportTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def raised_error(klass = StandardError, message = "test error")
    raise klass, message
  rescue => e
    e
  end

  test "report creates error report from exception" do
    report = ErrorReport.report(raised_error, severity: "error", source: "manual")

    assert report.persisted?
    assert_equal "StandardError", report.error_class
    assert_equal "test error", report.message
    assert report.fingerprint.present?
    assert_equal "error", report.severity
    assert_equal "manual", report.source
  end

  test "report extracts request information" do
    request = ActionDispatch::TestRequest.create
    request.path = "/test"
    user = User.create!

    report = ErrorReport.report(raised_error, request: request, user: user, source: "web")

    assert report.persisted?
    assert_equal "GET", report.request_method
    assert report.request_url.present?
    assert_equal user.id, report.user_id
    assert report.ip_address.present?
  end

  test "report filters sensitive parameters" do
    request = ActionDispatch::TestRequest.create
    request.path = "/test"
    request.request_parameters = { "password" => "secret123", "name" => "visible" }

    report = ErrorReport.report(raised_error, request: request, source: "web")

    assert report.persisted?
    assert_equal "[FILTERED]", report.request_params["password"]
    assert_equal "visible", report.request_params["name"]
  end

  test "fingerprint is consistent for same exception location" do
    fp1 = ErrorReport.generate_fingerprint(raised_error(StandardError, "error one"))
    fp2 = ErrorReport.generate_fingerprint(raised_error(StandardError, "error two"))

    assert_equal fp1, fp2, "Same class and location should produce same fingerprint"
  end

  test "resolve and unresolve" do
    report = ErrorReport.create!(error_class: "X", fingerprint: "fp")

    assert_nil report.resolved_at
    assert_not report.resolved?

    report.resolve!
    assert report.resolved?
    assert report.resolved_at.present?

    report.unresolve!
    assert_not report.resolved?
    assert_nil report.resolved_at
  end

  test "scopes" do
    unresolved = ErrorReport.create!(error_class: "X", fingerprint: "a")
    resolved = ErrorReport.create!(error_class: "X", fingerprint: "b", resolved_at: Time.current)

    assert_includes ErrorReport.unresolved, unresolved
    assert_not_includes ErrorReport.resolved, unresolved
    assert_includes ErrorReport.resolved, resolved
    assert_not_includes ErrorReport.unresolved, resolved
  end

  test "report does not raise on save failure" do
    ErrorReport.stub(:create!, ->(_) { raise ActiveRecord::RecordInvalid }) do
      assert_nil ErrorReport.report(raised_error)
    end
  end

  test "report logs failure with app_name prefix" do
    ErrorReporting.config.app_name = "MyApp"
    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(io)

    ErrorReport.stub(:create!, ->(_) { raise ActiveRecord::RecordInvalid }) do
      ErrorReport.report(raised_error)
    end

    assert_match(/\[MyApp\] \[ErrorReport\] Failed to save error report/, io.string)
  ensure
    Rails.logger = original_logger
    ErrorReporting.config.app_name = nil
  end

  test "validates severity inclusion" do
    report = ErrorReport.new(error_class: "Test", fingerprint: "abc", severity: "critical")
    assert_not report.valid?
    assert_includes report.errors[:severity], "is not included in the list"
  end

  test "validates source inclusion" do
    report = ErrorReport.new(error_class: "Test", fingerprint: "abc", source: "unknown")
    assert_not report.valid?
    assert_includes report.errors[:source], "is not included in the list"
  end

  test "report enqueues notification email" do
    ErrorReporting.config.notification_email = "errors@example.com"

    assert_enqueued_emails 1 do
      ErrorReport.report(raised_error(StandardError, "notify me"), severity: "error", source: "web")
    end
  ensure
    ErrorReporting.config.notification_email = nil
  end

  test "report throttles notification for same fingerprint within an hour" do
    ErrorReporting.config.notification_email = "errors@example.com"
    exception = raised_error(StandardError, "duplicate error")

    assert_enqueued_emails 1 do
      ErrorReport.report(exception, severity: "error", source: "web")
      ErrorReport.report(exception, severity: "error", source: "web")
    end
  ensure
    ErrorReporting.config.notification_email = nil
  end

  test "report honours configurable email throttle period" do
    ErrorReporting.config.notification_email = "errors@example.com"
    ErrorReporting.config.email_throttle_period = 0.seconds

    exception = raised_error(StandardError, "throttle window")

    # With a zero-second window, every report should enqueue an email.
    assert_enqueued_emails 2 do
      ErrorReport.report(exception, severity: "error", source: "web")
      ErrorReport.report(exception, severity: "error", source: "web")
    end
  ensure
    ErrorReporting.config.notification_email = nil
    ErrorReporting.config.email_throttle_period = 1.hour
  end

  test "user association uses configured class name" do
    reflection = ErrorReport.reflect_on_association(:user)
    assert_equal "User", reflection.options[:class_name]
    assert reflection.options[:optional]
  end
end
