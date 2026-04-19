class CreateErrorReports < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :error_reports do |t|
      t.string :error_class, null: false
      t.text :message
      t.text :backtrace
      t.string :fingerprint, null: false
      t.string :request_method
      t.text :request_url
      t.jsonb :request_params, default: {}
      t.jsonb :request_headers, default: {}
      t.references :user, foreign_key: true
      t.string :ip_address
      t.string :severity, default: "error", null: false
      t.string :source, default: "web", null: false
      t.datetime :resolved_at
      t.jsonb :context, default: {}
      t.timestamps
    end

    add_index :error_reports, :fingerprint
    add_index :error_reports, :error_class
    add_index :error_reports, :resolved_at
    add_index :error_reports, :created_at
    add_index :error_reports, :severity
  end
end
