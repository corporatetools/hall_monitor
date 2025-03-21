require "spec_helper"

RSpec.describe HallMonitor::FieldMap do
  # Define helper methods or let variables for testing
  let(:test_model_table) { TestModel.table_name } # "test_models"

  describe "initialization and standardization" do
    context "when initialized with nil" do
      it "excludes everything" do
        field_map = described_class.new(nil)
        expect(field_map.map).to be_nil
      end
    end

    context "when initialized with an empty hash" do
      it "includes everything" do
        field_map = described_class.new({})
        expect(field_map.map).to eq({})
      end
    end

    context "when initialized with an empty array" do
      it "excludes everything" do
        field_map = described_class.new([])
        expect(field_map.map).to be_nil
      end
    end

    context "when initialized with [{}]" do
      it "includes everything" do
        field_map = described_class.new([{}])
        expect(field_map.map).to eq({})
      end
    end

    context "when initialized with a table name as string" do
      it "includes all fields for the specified table" do
        field_map = described_class.new("test_models")
        expect(field_map.map).to eq({"test_models" => nil})
      end
    end

    context "when initialized with a table name as symbol" do
      it "includes all fields for the specified table" do
        field_map = described_class.new(:test_models)
        expect(field_map.map).to eq({"test_models" => nil})
      end
    end

    context "when initialized with a mock ActiveRecord model class" do
      it "includes all fields for the model's table" do
        field_map = described_class.new(TestModel)
        expect(field_map.map).to eq({"test_models" => nil})
      end
    end

    context "when initialized with a hash with a table key and nil value" do
      it "includes all fields for the specified table" do
        field_map = described_class.new({"test_models" => nil})
        expect(field_map.map).to eq({"test_models" => nil})
      end
    end

    context "when initialized with a hash with a table key and single field" do
      it "includes only the specified field for the table" do
        field_map = described_class.new({test_models: :name})
        expect(field_map.map).to eq({"test_models" => ["name"]})
      end
    end

    context "when initialized with a hash with a table key and multiple fields" do
      it "includes only the specified fields for the table" do
        field_map = described_class.new({TestModel => ["name", :description]})
        expect(field_map.map).to eq({"test_models" => ["name", "description"]})
      end
    end

    context "when initialized with an array of various options" do
      it "standardizes the map correctly" do
        field_map = described_class.new([
          "test_models",
          {TestModel => ["name", "description"]},
          test_models: :created_at
        ])
        expected_map = {
          "test_models" => ["name", "description", "created_at"]
        }
        expect(field_map.map).to eq(expected_map)
      end
    end
  end

  describe "includes_everything? and excludes_everything?" do
    context "when map is nil" do
      it "excludes everything" do
        field_map = described_class.new(nil)
        expect(field_map.excludes_everything?).to be true
        expect(field_map.includes_everything?).to be false
      end
    end

    context "when map is empty hash" do
      it "includes everything" do
        field_map = described_class.new({})
        expect(field_map.includes_everything?).to be true
        expect(field_map.excludes_everything?).to be false
      end
    end

    context "when map includes specific tables" do
      it "does not include everything or exclude everything" do
        field_map = described_class.new({"test_models" => ["name"]})
        expect(field_map.includes_everything?).to be false
        expect(field_map.excludes_everything?).to be false
      end
    end
  end

  describe "includes_table?" do
    context "when includes_everything is true" do
      it "includes any table" do
        field_map = described_class.new({})
        expect(field_map.includes_table?(test_model_table)).to be true
        expect(field_map.includes_table?("nonexistent")).to be true
      end
    end

    context "when excludes_everything is true" do
      it "does not include any table" do
        field_map = described_class.new(nil)
        expect(field_map.includes_table?(test_model_table)).to be false
      end
    end

    context "when specific tables are included" do
      it "includes only specified tables" do
        field_map = described_class.new({"test_models" => ["name"]})
        expect(field_map.includes_table?(test_model_table)).to be true
        expect(field_map.includes_table?("other_table")).to be false
      end
    end
  end

  describe "includes_everything_for_table?" do
    context "when includes_everything is true" do
      it "includes everything for any table" do
        field_map = described_class.new({})
        expect(field_map.includes_everything_for_table?(test_model_table)).to be true
      end
    end

    context "when specific tables have all fields included" do
      it "returns true for those tables" do
        field_map = described_class.new({"test_models" => nil})
        expect(field_map.includes_everything_for_table?(test_model_table)).to be true
      end
    end

    context "when table has specific fields" do
      it "returns false" do
        field_map = described_class.new({"test_models" => ["name"]})
        expect(field_map.includes_everything_for_table?(test_model_table)).to be false
      end
    end

    context "when table is not included" do
      it "returns false" do
        field_map = described_class.new({"other_table" => ["name"]})
        expect(field_map.includes_everything_for_table?(test_model_table)).to be false
      end
    end
  end

  describe "includes_field?" do
    context "when table is included with all fields" do
      it "includes any field" do
        field_map = described_class.new({"test_models" => nil})
        expect(field_map.includes_field?("test_models", "name")).to be true
        expect(field_map.includes_field?("test_models", :description)).to be true
      end
    end

    context "when table is included with specific fields" do
      it "includes only specified fields" do
        field_map = described_class.new({"test_models" => ["name", "description"]})
        expect(field_map.includes_field?("test_models", "name")).to be true
        expect(field_map.includes_field?("test_models", :description)).to be true
        expect(field_map.includes_field?("test_models", "other_field")).to be false
      end
    end

    context "when table is not included" do
      it "does not include any fields" do
        field_map = described_class.new({"other_table" => ["name"]})
        expect(field_map.includes_field?("test_models", "name")).to be false
      end
    end
  end

  describe "overlaps_with?" do
    context "when either map excludes everything" do
      it "returns false" do
        map1 = described_class.new(nil)
        map2 = described_class.new({"test_models" => ["name"]})
        expect(map1.overlaps_with?(map2)).to be false
        expect(map2.overlaps_with?(map1)).to be false
      end
    end

    context "when either map includes everything" do
      it "returns true" do
        map1 = described_class.new({})
        map2 = described_class.new({"test_models" => ["name"]})
        expect(map1.overlaps_with?(map2)).to be true
        expect(map2.overlaps_with?(map1)).to be true
      end
    end

    context "when maps have overlapping tables with overlapping fields" do
      it "returns true" do
        map1 = described_class.new({"test_models" => ["name", "description"]})
        map2 = described_class.new({"test_models" => ["description"]})
        expect(map1.overlaps_with?(map2)).to be true
      end
    end

    context "when maps have overlapping tables but no overlapping fields" do
      it "returns false" do
        map1 = described_class.new({"test_models" => ["name"]})
        map2 = described_class.new({"test_models" => ["description"]})
        expect(map1.overlaps_with?(map2)).to be false
      end
    end
  end

  describe ".build" do
    context "when input is already a FieldMap" do
      it "returns the same instance" do
        existing_map = described_class.new({"test_models" => ["name"]})
        built_map = described_class.build(existing_map)
        expect(built_map).to eq(existing_map)
      end
    end

    context "when input is not a FieldMap" do
      it "creates a new FieldMap instance" do
        input = {"test_models" => ["name"]}
        built_map = described_class.build(input)
        expect(built_map).to be_a(described_class)
        expect(built_map.map).to eq(input)
      end
    end
  end
end
