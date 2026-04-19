ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "minitest/mock"

# Load schema into the in-memory SQLite database.
ActiveRecord::Migration.verbose = false
load File.expand_path("dummy/db/schema.rb", __dir__)

class ActiveSupport::TestCase
  parallelize(workers: 1)
end
