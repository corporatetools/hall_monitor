# Manages a mapping of fields to tables in a standardized way.
# Flexible input, but gets converted to a standard format for easy comparison.

# ALLOWABLE INPUT FORMAT
# - nil - empty map. No fields are included.
# - {} - wildcard. All fields are included.
# - A string or symbol representing a table name. All fields for this table are included.
# - An ActiveRecord model class, from which a table name will be inferred. All fields are included.
# - A hash with a single key that is a string, symbol, or ActiveRecord model class, where the value is:
#   - Nil - All fields for this table are included
#   - A string or symbol representing a field name
#   - An array of strings or symbols representing field names
# - An array of any of the above options. Each element is treated as a separate table.

# STANDARDIZED FORMAT
# {
#  "table_name" => ["field_name", "field_name", ...],
#  "table_name" => nil, # all fields for this table
#  ...
# }
# All keys and values are strings. Empty hash means all fields are included.
# Can also be a nil, which means no fields are included.

module HallMonitor
  class FieldMap
    attr_reader :map

    def initialize(map)
      self.map = map
    end

    def map=(map)
      @map = self.class.standardize map
    end

    def table_names
      map&.keys
    end

    def includes_everything?
      map == {}
    end

    def excludes_everything?
      map.nil?
    end

    def includes_table?(table_name)
      return true if includes_everything?
      return false if excludes_everything?
      map.key?(table_name)
    end

    def includes_everything_for_table?(table_name)
      return true if includes_everything?
      return false unless includes_table?(table_name)
      map[table_name].nil? # nil means all fields for this table
    end

    def includes_field?(table_name, field)
      return false unless includes_table?(table_name)
      return true if includes_everything_for_table?(table_name)
      map[table_name].include?(field.to_s)
    end

    # Returns true if this field map shares any fields with the other field map.
    def overlaps_with?(other)
      other = self.class.new(other) unless other.is_a?(self.class)
      return false if excludes_everything? || other.excludes_everything?
      return true if includes_everything? || other.includes_everything?

      table_names.any? do |table_name|
        next false unless other.includes_table?(table_name)
        next true if includes_everything_for_table?(table_name) || other.includes_everything_for_table?(table_name)
        (map[table_name] & other.map[table_name]).any?
      end
    end

    def self.build(input)
      input.is_a?(self) ? input : new(input)
    end

    def self.standardize(map)
      return nil if map.nil?
      return nil if map.is_a?(Array) && map.empty?

      map = [map] unless map.is_a?(Array)

      map.each_with_object({}) do |option, standardized|
        next if option.nil?
        option = {option => nil} unless option.is_a?(Hash)

        option.each do |key, value|
          next if key.nil? || key.to_s.strip.empty?

          table_name = (key.is_a?(Class) && key < ActiveRecord::Base) ? key.table_name : key.to_s
          attributes = value.nil? ? nil : Array(value).map(&:to_s)

          if standardized[table_name]
            if standardized[table_name].nil? || attributes.nil?
              standardized[table_name] = nil # all columns for this table
            else
              standardized[table_name] += attributes
              standardized[table_name].uniq!
            end
          else
            standardized[table_name] = attributes
          end
        end
      end
    end
  end
end
