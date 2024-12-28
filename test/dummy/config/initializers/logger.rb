# frozen_string_literal: true

# config/initializers/active_record_logging.rb

module ActiveRecord
  class LogSubscriberWithDatabase < ActiveRecord::LogSubscriber
    def sql(event)
      config = event.payload[:connection].instance_variable_get(:@config)
      parts = [
        "[A##{Thread.current.name || :main}]",
        "[T##{Thread.current.object_id}]",
        "[C##{event.payload[:connection].object_id}]",
        "[#{config[:adapter].downcase}/#{config[:database].split("/").last}]"
      ]
      event.payload[:name] = "#{Time.current} -- #{parts.join(" ")} #{event.payload[:name]}"
    end
  end
end

# prepend the new log subscriber: detach rails default log subscriber and attach this one then reattach the default log subscriber
ActiveRecord::LogSubscriber.detach_from :active_record
ActiveRecord::LogSubscriberWithDatabase.attach_to :active_record
ActiveRecord::LogSubscriber.attach_to :active_record
