require "test_helper"

class ErrorReportSubscriberTest < ActiveSupport::TestCase
  test "reports errors from jobs" do
    assert_difference "ErrorReport.count", 1 do
      ErrorReportSubscriber.new.report(StandardError.new("boom"), handled: false, severity: :error, source: "application.active_job")
    end

    assert_equal "job", ErrorReport.last.source
  end

  test "reports manually reported errors" do
    assert_difference "ErrorReport.count", 1 do
      Rails.error.report(StandardError.new("boom"))
    end
  end

  test "skips unhandled request errors already reported by the middleware" do
    assert_no_difference "ErrorReport.count" do
      ErrorReportSubscriber.new.report(StandardError.new("boom"), handled: false, severity: :error, source: "application.action_dispatch")
    end
  end
end
