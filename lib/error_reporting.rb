require "error_reporting/version"
require "error_reporting/configuration"
require "error_reporter_middleware"
require "error_reporting/engine"

module ErrorReporting
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end
  end
end
