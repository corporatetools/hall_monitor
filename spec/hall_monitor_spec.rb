require "spec_helper"

RSpec.describe HallMonitor do
  it "has a version number" do
    expect(HallMonitor::VERSION).not_to be nil
  end

  describe ".configure" do
    it "configures the module with a block" do
      test_emitter = ->(data_change) { puts "Test emitter called" }

      described_class.configure do |config|
        config.publisher_name = "Test Publisher"
        config.emitter = test_emitter
      end

      expect(described_class.config.publisher_name).to eq("Test Publisher")
      expect(described_class.config.emitter).to eq(test_emitter)
    end

    it "provides default values" do
      described_class.configure

      expect(described_class.config.publisher_name).to eq("Hall Monitor")
      expect(described_class.config.producer_topic).to eq("hall_monitor")
      expect(described_class.config.emitter).to be_a(Proc)
      expect(described_class.config.consumer).to be_a(Proc)
    end
  end

  describe ".register_watcher" do
    it "adds a watcher to the list" do
      watcher = HallMonitor::Watcher.new(
        field_map: {TestModel => :name},
        callback: ->(data_change) {}
      )

      described_class.register_watcher(watcher)

      expect(described_class.watchers).to include(watcher)
    end

    it "prevents adding the same watcher twice" do
      watcher = HallMonitor::Watcher.new(
        field_map: {TestModel => :name},
        callback: ->(data_change) {}
      )

      described_class.register_watcher(watcher)
      described_class.register_watcher(watcher)

      expect(described_class.watchers.count(watcher)).to eq(1)
    end

    it "raises an error when not given a Watcher" do
      expect {
        described_class.register_watcher("not a watcher")
      }.to raise_error(ArgumentError, "Watcher must be a HallMonitor::Watcher object")
    end
  end

  describe ".emit_data_change" do
    it "calls the configured emitter" do
      emitted_change = nil
      described_class.configure do |config|
        config.emitter = ->(data_change) { emitted_change = data_change }
      end

      data_change = HallMonitor::DataChange.new(
        table: "test_models",
        operation: :update,
        changes: {"name" => ["Old Name", "New Name"]}
      )

      described_class.emit_data_change(data_change)

      expect(emitted_change).to eq(data_change)
    end
  end

  describe ".consume_data_change" do
    it "routes the data change to interested watchers" do
      interest_detected = false
      interested_watcher = HallMonitor::Watcher.new(
        field_map: {TestModel => :name},
        callback: ->(data_change) { interest_detected = true }
      )

      uninterested_watcher = HallMonitor::Watcher.new(
        field_map: {TestModel => :other_field},
        callback: ->(data_change) { raise "Should not be called" }
      )

      described_class.watchers.clear
      described_class.register_watcher(interested_watcher)
      described_class.register_watcher(uninterested_watcher)

      data_change = HallMonitor::DataChange.new(
        table: TestModel.table_name,
        operation: :update,
        changes: {"name" => ["Old Name", "New Name"]}
      )

      described_class.consume_data_change(data_change)

      expect(interest_detected).to be true
    end
  end

  # Clean up after all tests
  after(:all) do
    # Reset the configuration and watchers
    described_class.configure
    described_class.watchers.clear
  end
end
