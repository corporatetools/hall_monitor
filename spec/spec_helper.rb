require "bundler/setup"
require "logger"
require "ostruct"

# Load HallMonitor directly without the ActiveRecord and ActiveSupport dependencies
# This is only for testing
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "hall_monitor/version"
require "hall_monitor/field_map"
require "hall_monitor/watcher"

# Create mock ActiveRecord module for testing
module ActiveRecord
  class Base
    def self.table_name
      "test_models"
    end
  end
end

# Create mock classes for testing
module HallMonitor
  class DataChange
    attr_accessor :table, :operation, :changes, :primary_key_name, :primary_key_value

    def initialize(options = {})
      @table = options[:table]
      @operation = options[:operation]&.to_s&.chr || "u"
      @changes = options[:changes] || {}
      @primary_key_name = options[:primary_key_name]
      @primary_key_value = options[:primary_key_value]
    end

    def field_changed?(field)
      changes.key?(field.to_s)
    end

    def changed_fields
      changes.keys
    end

    def old_value_for(field)
      changes[field.to_s]&.first
    end

    def new_value_for(field)
      changes[field.to_s]&.last
    end

    def as_hash
      {
        table: table,
        primary_key_name: primary_key_name,
        primary_key_value: primary_key_value,
        operation: operation,
        changes: changes,
        publisher: "test"
      }
    end
  end

  module ActiveRecordExtensions
    # Mock implementation for tests
  end

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

# Mock ActiveRecord::Base for testing
class MockActiveRecord < ActiveRecord::Base
  def self.table_name
    "test_models"
  end
end

# RSpec configuration
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset HallMonitor configuration between tests
  config.before(:each) do
    HallMonitor.configure do |c|
      c.publisher_name = "Hall Monitor"
      c.producer_topic = "hall_monitor"
      c.emitter = ->(_data_change) {}
      c.consumer = ->(_data_change) {}
    end
    HallMonitor.watchers.clear
  end
end

# Helper methods for testing
def capture_changes
  changes = []
  HallMonitor.configure do |config|
    config.emitter = ->(data_change) {
      changes << data_change
    }
  end
  changes
end

# Constants for tests
TestModel = MockActiveRecord
