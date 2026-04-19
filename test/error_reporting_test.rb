require "test_helper"

class ErrorReportingTest < ActiveSupport::TestCase
  test "configure yields the current config" do
    previous = ErrorReporting.config.user_class_name

    ErrorReporting.configure do |c|
      c.user_class_name = "Admin"
    end

    assert_equal "Admin", ErrorReporting.config.user_class_name
  ensure
    ErrorReporting.config.user_class_name = previous
  end

  test "config defaults" do
    fresh = ErrorReporting::Configuration.new
    assert_equal "User", fresh.user_class_name
    assert_equal 1.hour, fresh.email_throttle_period
    assert_nil fresh.notification_email
    assert_nil fresh.from_address
    assert_nil fresh.from_name
    assert_nil fresh.app_name
  end

  test "resolved_* return nil when unset" do
    fresh = ErrorReporting::Configuration.new
    assert_nil fresh.resolved_notification_email
    assert_nil fresh.resolved_from_address
    assert_nil fresh.resolved_from_name
    assert_nil fresh.resolved_app_name
  end

  test "resolved_* return configured values verbatim" do
    fresh = ErrorReporting::Configuration.new
    fresh.notification_email = "errors@example.com"
    fresh.from_address = "alerts@example.com"
    fresh.from_name = "Error Reporter"
    fresh.app_name = "MyApp"

    assert_equal "errors@example.com", fresh.resolved_notification_email
    assert_equal "alerts@example.com", fresh.resolved_from_address
    assert_equal "Error Reporter", fresh.resolved_from_name
    assert_equal "MyApp", fresh.resolved_app_name
  end

  test "resolved_* evaluate callables" do
    fresh = ErrorReporting::Configuration.new
    fresh.notification_email = -> { "dynamic@example.com" }
    fresh.from_address = -> { "dynamic-from@example.com" }
    fresh.from_name = -> { "Dynamic Name" }
    fresh.app_name = -> { "DynamicApp" }

    assert_equal "dynamic@example.com", fresh.resolved_notification_email
    assert_equal "dynamic-from@example.com", fresh.resolved_from_address
    assert_equal "Dynamic Name", fresh.resolved_from_name
    assert_equal "DynamicApp", fresh.resolved_app_name
  end

  test "log_tag wraps component in brackets when app_name is blank" do
    fresh = ErrorReporting::Configuration.new
    assert_equal "[ErrorReport]", fresh.log_tag("ErrorReport")
  end

  test "log_tag prepends app_name as a separate tag when set" do
    fresh = ErrorReporting::Configuration.new
    fresh.app_name = "MyApp"
    assert_equal "[MyApp] [ErrorReport]", fresh.log_tag("ErrorReport")
  end

  test "engine is loaded and Rails::Engine subclass" do
    assert ErrorReporting::Engine < Rails::Engine
  end

  test "middleware is installed in the stack" do
    middleware_classes = Rails.application.middleware.map(&:klass)
    assert_includes middleware_classes, ErrorReporterMiddleware
  end
end
