module ErrorReporting
  class Configuration
    attr_accessor :user_class_name, :notification_email, :from_address, :from_name, :app_name, :email_throttle_period

    def initialize
      @user_class_name = "User"
      @notification_email = nil
      @from_address = nil
      @from_name = nil
      @app_name = nil
      @email_throttle_period = 1.hour
    end

    def resolved_notification_email
      evaluate(notification_email)
    end

    def resolved_from_address
      evaluate(from_address)
    end

    def resolved_from_name
      evaluate(from_name)
    end

    def resolved_app_name
      evaluate(app_name)
    end

    def log_tag(component)
      name = resolved_app_name
      name.present? ? "[#{name}] [#{component}]" : "[#{component}]"
    end

    private

    def evaluate(value)
      value.respond_to?(:call) ? value.call : value
    end
  end
end
