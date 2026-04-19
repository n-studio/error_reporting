require "rails/generators"
require "rails/generators/migration"

module ErrorReporting
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Copies the error_reporting initializer and migration into the host app."

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        [ Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % next_migration_number ].max
      end

      def copy_initializer
        template "error_reporting.rb", "config/initializers/error_reporting.rb"
      end

      def copy_migration
        migration_template(
          "create_error_reports.rb",
          "db/migrate/create_error_reports.rb",
          migration_version: migration_version
        )
      end

      private

      def migration_version
        "[#{ActiveRecord::Migration.current_version}]"
      end
    end
  end
end
