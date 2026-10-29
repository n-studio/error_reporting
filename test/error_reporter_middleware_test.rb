require "test_helper"

class ErrorReporterMiddlewareTest < ActiveSupport::TestCase
  def call_with(exception)
    middleware = ErrorReporterMiddleware.new(->(_env) { raise exception })
    env = Rack::MockRequest.env_for("/test")

    assert_raises(exception.class) { middleware.call(env) }
  end

  test "reports server errors" do
    assert_difference "ErrorReport.count", 1 do
      call_with(StandardError.new("boom"))
    end
  end

  test "does not report ActionController::UnknownFormat" do
    assert_no_difference "ErrorReport.count" do
      call_with(ActionController::UnknownFormat.new)
    end
  end

  test "does not report ActionController::RoutingError" do
    assert_no_difference "ErrorReport.count" do
      call_with(ActionController::RoutingError.new("No route matches"))
    end
  end

  test "does not report ActiveRecord::RecordNotFound" do
    assert_no_difference "ErrorReport.count" do
      call_with(ActiveRecord::RecordNotFound.new)
    end
  end
end
