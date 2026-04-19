require "test_helper"

class ErrorReportMailerTest < ActionMailer::TestCase
  setup do
    ErrorReporting.config.notification_email = "errors@example.com"
    @report = ErrorReport.create!(
      error_class: "ActiveRecord::RecordNotFound",
      message: "Couldn't find User with 'id'=999",
      fingerprint: "abc123def456",
      severity: "error",
      source: "web"
    )
  end

  teardown do
    ErrorReporting.config.notification_email = nil
    ErrorReporting.config.from_address = nil
    ErrorReporting.config.from_name = nil
    ErrorReporting.config.app_name = nil
  end

  test "error_occurred sends to configured email" do
    email = ErrorReportMailer.error_occurred(@report)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "errors@example.com" ], email.to
    assert_includes email.subject, "ERROR"
    assert_includes email.subject, "ActiveRecord::RecordNotFound"
  end

  test "subject uses bare env prefix when app_name is blank" do
    email = ErrorReportMailer.error_occurred(@report)
    assert_equal "[test] ERROR: ActiveRecord::RecordNotFound", email.subject
  end

  test "subject includes app_name when set" do
    ErrorReporting.config.app_name = "MyApp"
    email = ErrorReportMailer.error_occurred(@report)
    assert_equal "[MyApp test] ERROR: ActiveRecord::RecordNotFound", email.subject
  end

  test "app_name accepts a callable" do
    ErrorReporting.config.app_name = -> { "DynamicApp" }
    email = ErrorReportMailer.error_occurred(@report)
    assert_equal "[DynamicApp test] ERROR: ActiveRecord::RecordNotFound", email.subject
  end

  test "error_occurred includes error details in body" do
    email = ErrorReportMailer.error_occurred(@report)

    assert_match "ActiveRecord::RecordNotFound", email.html_part.body.to_s
    assert_match "ActiveRecord::RecordNotFound", email.text_part.body.to_s
  end

  test "error_occurred silently skips when notification_email is blank" do
    ErrorReporting.config.notification_email = nil
    email = ErrorReportMailer.error_occurred(@report)

    assert_emails 0 do
      email&.deliver_now
    end
  end

  test "notification_email accepts a callable" do
    ErrorReporting.config.notification_email = -> { "lambda@example.com" }

    email = ErrorReportMailer.error_occurred(@report)
    email.deliver_now

    assert_equal [ "lambda@example.com" ], email.to
  end

  test "from_address falls back to ApplicationMailer default when unset" do
    email = ErrorReportMailer.error_occurred(@report)
    email.deliver_now

    assert_equal [ "no-reply@example.com" ], email.from
  end

  test "from_address uses ErrorReporting.config.from_address when set" do
    ErrorReporting.config.from_address = "alerts@example.com"

    email = ErrorReportMailer.error_occurred(@report)
    email.deliver_now

    assert_equal [ "alerts@example.com" ], email.from
  end

  test "from header includes display name when from_name is set" do
    ErrorReporting.config.from_address = "alerts@example.com"
    ErrorReporting.config.from_name = "Error Reporter"

    email = ErrorReportMailer.error_occurred(@report)
    email.deliver_now

    assert_equal [ "alerts@example.com" ], email.from
    assert_equal "Error Reporter <alerts@example.com>", email[:from].decoded
  end

  test "from_name accepts a callable" do
    ErrorReporting.config.from_address = "alerts@example.com"
    ErrorReporting.config.from_name = -> { "Lambda Name" }

    email = ErrorReportMailer.error_occurred(@report)
    email.deliver_now

    assert_equal "Lambda Name <alerts@example.com>", email[:from].decoded
  end
end
