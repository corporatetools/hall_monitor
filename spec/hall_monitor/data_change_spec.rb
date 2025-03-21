require "spec_helper"

RSpec.describe HallMonitor::DataChange do
  describe "initialization" do
    it "initializes with table and operation parameters" do
      data_change = described_class.new(
        table: "test_models",
        operation: :update
      )

      expect(data_change.table).to eq("test_models")
      expect(data_change.operation).to eq("u")
    end

    it "initializes with changes hash" do
      changes = {"name" => ["Old Name", "New Name"]}
      data_change = described_class.new(changes: changes)

      expect(data_change.changes).to eq(changes)
    end
  end

  describe "change inspection" do
    let(:data_change) do
      described_class.new(
        table: "test_models",
        operation: :update,
        changes: {
          "name" => ["Old Name", "New Name"],
          "description" => ["Old Description", "New Description"]
        }
      )
    end

    it "detects changed fields" do
      expect(data_change.field_changed?("name")).to be true
      expect(data_change.field_changed?(:name)).to be true
      expect(data_change.field_changed?("other_field")).to be false
    end

    it "returns list of changed fields" do
      expect(data_change.changed_fields).to contain_exactly("name", "description")
    end

    it "retrieves old value for a field" do
      expect(data_change.old_value_for("name")).to eq("Old Name")
      expect(data_change.old_value_for(:description)).to eq("Old Description")
    end

    it "retrieves new value for a field" do
      expect(data_change.new_value_for("name")).to eq("New Name")
      expect(data_change.new_value_for(:description)).to eq("New Description")
    end
  end

  describe "#as_hash" do
    it "returns a hash representation" do
      data_change = described_class.new(
        table: "test_models",
        operation: :create,
        changes: {"name" => [nil, "Test"]},
        primary_key_name: "id",
        primary_key_value: 123
      )

      hash = data_change.as_hash

      expect(hash).to be_a(Hash)
      expect(hash[:table]).to eq("test_models")
      expect(hash[:operation]).to eq("c")
      expect(hash[:changes]).to eq({"name" => [nil, "Test"]})
      expect(hash[:primary_key_name]).to eq("id")
      expect(hash[:primary_key_value]).to eq(123)
    end
  end
end
