require "test_helper"

class RequestErrorReportingTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.routes.draw do
      get "/boom", to: ->(_env) { raise "boom" }
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "an unhandled request error is reported once" do
    assert_difference "ErrorReport.count", 1 do
      assert_raises(RuntimeError) { get "/boom" }
    end

    assert_equal "/boom", URI(ErrorReport.last.request_url).path
  end
end
