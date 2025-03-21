require "logger" # Ensure Logger is loaded first
require "active_support"
require "active_record"
require "ostruct"

require_relative "hall_monitor/version"
require_relative "hall_monitor/field_map"
require_relative "hall_monitor/data_change"
require_relative "hall_monitor/watcher"
require_relative "hall_monitor/watcher_behavior"
require_relative "hall_monitor/watcher_base"
require_relative "hall_monitor/active_record_extensions"

module HallMonitor
  class << self
    attr_accessor :config
    attr_writer :watchers

    def configure
      self.config ||= OpenStruct.new(
        publisher_name: "Hall Monitor",
        producer_topic: "hall_monitor",
        emitter: ->(_data_change) {},
        consumer: ->(_data_change) {}
      )
      yield config if block_given?
    end

    def watchers
      @watchers ||= []
    end

    def register_watcher(watcher)
      raise ArgumentError, "Watcher must be a HallMonitor::Watcher object" unless watcher.is_a?(HallMonitor::Watcher)
      watchers << watcher
      watchers.uniq!
    end

    def emit_data_change(data_change)
      config.emitter&.call(data_change)
    end

    def consume_data_change(data_change)
      watchers.each do |watcher|
        watcher.execute_if_interested(data_change)
      end
    end
  end
end
