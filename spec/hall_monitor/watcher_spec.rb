require "spec_helper"

RSpec.describe HallMonitor::Watcher do
  let(:callback) { ->(data_change) { @change_detected = true } }
  let(:test_model_table) { TestModel.table_name }

  before do
    @change_detected = false
  end

  describe "#initialize" do
    it "creates a watcher with the field_map and callback" do
      watcher = described_class.new(
        field_map: {TestModel => :name},
        callback: callback
      )

      expect(watcher.field_map).to be_a(HallMonitor::FieldMap)
      expect(watcher.callback).to eq(callback)
      expect(watcher.operations).to be_nil
    end

    it "accepts an operations parameter" do
      watcher = described_class.new(
        field_map: {TestModel => :name},
        callback: callback,
        operations: [:create, :update]
      )

      expect(watcher.operations).to contain_exactly(:create, :update)
    end
  end

  describe "#interested_in?" do
    let(:watcher) do
      described_class.new(
        field_map: {TestModel => ["name", "description"]},
        callback: callback
      )
    end

    it "returns true when data change matches the field map" do
      data_change = HallMonitor::DataChange.new(
        table: test_model_table,
        operation: :update,
        changes: {"name" => ["Old Name", "New Name"]}
      )

      expect(watcher.interested_in?(data_change)).to be true
    end

    it "returns false when data change doesn't match the field map" do
      data_change = HallMonitor::DataChange.new(
        table: test_model_table,
        operation: :update,
        changes: {"other_field" => ["Old Value", "New Value"]}
      )

      expect(watcher.interested_in?(data_change)).to be false
    end

    it "respects the operations filter" do
      watcher_with_operations = described_class.new(
        field_map: {TestModel => :name},
        callback: callback,
        operations: [:update]
      )

      create_change = HallMonitor::DataChange.new(
        table: test_model_table,
        operation: :create,
        changes: {"name" => [nil, "New Name"]}
      )

      update_change = HallMonitor::DataChange.new(
        table: test_model_table,
        operation: :update,
        changes: {"name" => ["Old Name", "New Name"]}
      )

      expect(watcher_with_operations.interested_in?(create_change)).to be false
      expect(watcher_with_operations.interested_in?(update_change)).to be true
    end
  end

  describe "#execute_if_interested" do
    let(:watcher) do
      described_class.new(
        field_map: {TestModel => :name},
        callback: callback
      )
    end

    it "executes the callback when interested" do
      data_change = HallMonitor::DataChange.new(
        table: test_model_table,
        operation: :update,
        changes: {"name" => ["Old Name", "New Name"]}
      )

      watcher.execute_if_interested(data_change)

      expect(@change_detected).to be true
    end

    it "doesn't execute the callback when not interested" do
      data_change = HallMonitor::DataChange.new(
        table: test_model_table,
        operation: :update,
        changes: {"other_field" => ["Old Value", "New Value"]}
      )

      watcher.execute_if_interested(data_change)

      expect(@change_detected).to be false
    end

    it "handles errors in the callback" do
      error_callback = ->(data_change) { raise "Test error" }
      error_watcher = described_class.new(
        field_map: {TestModel => :name},
        callback: error_callback
      )

      data_change = HallMonitor::DataChange.new(
        table: test_model_table,
        operation: :update,
        changes: {"name" => ["Old Name", "New Name"]}
      )

      expect { error_watcher.execute_if_interested(data_change) }.to raise_error("Test error")
    end
  end
end
