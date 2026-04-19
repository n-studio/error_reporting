ActiveRecord::Schema[8.0].define(version: 2026_03_15_000000) do
  create_table :users, force: :cascade do |t|
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  create_table :error_reports, force: :cascade do |t|
    t.string :error_class, null: false
    t.text :message
    t.text :backtrace
    t.string :fingerprint, null: false
    t.string :request_method
    t.text :request_url
    t.json :request_params, default: {}
    t.json :request_headers, default: {}
    t.references :user
    t.string :ip_address
    t.string :severity, default: "error", null: false
    t.string :source, default: "web", null: false
    t.datetime :resolved_at
    t.json :context, default: {}
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  add_index :error_reports, :fingerprint
  add_index :error_reports, :error_class
  add_index :error_reports, :resolved_at
  add_index :error_reports, :created_at
  add_index :error_reports, :severity
end
