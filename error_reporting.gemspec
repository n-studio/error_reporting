require_relative "lib/error_reporting/version"

Gem::Specification.new do |spec|
  spec.name        = "error_reporting"
  spec.version     = ErrorReporting::VERSION
  spec.authors     = [ "n-studio" ]
  spec.summary     = "Rails error capture, storage, and email notification."
  spec.description = "Persists unhandled exceptions as ErrorReport records, sends throttled email notifications, and hooks into Rails' error reporter and Rack stack."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir[
    "{app,config,lib}/**/*",
    "README.md"
  ]

  spec.add_dependency "rails", ">= 8.0"

  spec.add_development_dependency "sqlite3", ">= 2.0"
  spec.add_development_dependency "minitest-mock"
end
