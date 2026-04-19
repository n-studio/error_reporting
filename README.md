# error_reporting

A Rails engine that captures unhandled exceptions, persists them as
`ErrorReport` records, and sends throttled email notifications.

It hooks into:

- Rails' error reporter (`Rails.error.subscribe`) — so `config.exceptions_app`
  and explicit `Rails.error.report` calls are captured.
- The Rack middleware stack — so exceptions escaping to the top of the stack
  are captured with full request context.

## Installation

```ruby
# Gemfile
gem "error_reporting", path: "vendor/gems/error_reporting"
```

Copy the initializer and migration into the host, then run it:

```sh
bin/rails generate error_reporting:install
bin/rails db:migrate
```

The generator creates:

- `config/initializers/error_reporting.rb` — edit this to configure the gem.
- `db/migrate/TIMESTAMP_create_error_reports.rb` — a copy of the migration
  with a fresh timestamp, matching standard Rails engine practice.

## Configuration

Edit `config/initializers/error_reporting.rb` (created by the generator):

```ruby
ErrorReporting.configure do |config|
  config.user_class_name = "User"                     # default: "User"
  config.app_name = "MyApp"                           # prefix for email subjects
  config.notification_email = "errors@example.com"    # string or callable
  config.from_address = "no-reply@example.com"        # string or callable
  config.from_name = "Error Reporter"                 # optional display name
  config.email_throttle_period = 1.hour               # default: 1.hour
end
```

- When `app_name` is set, the subject reads `[MyApp production] ERROR: NoMethodError`.
  Otherwise it falls back to `[production] ERROR: NoMethodError`.
- When `notification_email` is blank, notifications are silently skipped.
- When `from_address` is blank, the `From:` header is inherited from
  `ApplicationMailer`'s default.
- When `from_name` is set alongside `from_address`, the header is composed
  via `email_address_with_name` (e.g. `Error Reporter <no-reply@example.com>`).

Configure these values in an initializer — not at runtime — because the
`belongs_to :user` association on `ErrorReport` captures
`user_class_name` when the model is first loaded.

## Usage

Exceptions are captured automatically. You can also report manually:

```ruby
ErrorReport.report(
  exception,
  request: request,    # optional
  user: current_user,  # optional
  severity: "error",   # "error", "warning", "info"
  source: "manual",    # "web", "job", "manual"
  context: { ... }     # optional metadata
)
```

## Admin UI

This gem does not ship an admin UI. Hosts are expected to build their own
index/show controllers on top of `ErrorReport`.

## Running the test suite

The gem ships a minimal dummy Rails app (SQLite, in-memory) under `test/dummy/`.

```sh
cd vendor/gems/error_reporting
bundle install
bundle exec rake test
```
