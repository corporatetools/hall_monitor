# frozen_string_literal: true

module HallMonitor
  class DataChange
    attr_reader \
      :database,
      :table,
      :primary_key_name,
      :primary_key_value,
      :operation,
      :changes,
      :all_fields

    def initialize(options)
      options = options.symbolize_keys

      # Our changes hash
      @changes = options[:changes] || {}

      # Possibly passed: an actual AR object
      object = options[:object]

      # If we have an object, we can fill from it — but prefer overrides from options.
      if object
        model_klass = object.class

        @database = options[:database] || model_klass.connection_db_config.database
        @table = options[:table] || model_klass.table_name
        @operation = (options[:operation] || "u").to_s.first
        @record = object

        # If primary_key_name/value explicitly provided, use them.
        # Otherwise, attempt to discover from the object.
        if options[:primary_key_name] && options[:primary_key_value]
          @primary_key_name = options[:primary_key_name]
          @primary_key_value = options[:primary_key_value]
          @all_fields = options[:all_fields]
        else
          # Attempt to find multi-column PKs if your Rails version or gem supports it.
          pk_columns = model_klass.primary_keys if model_klass.respond_to?(:primary_keys)
          pk_columns ||= [model_klass.primary_key].compact

          if pk_columns.empty?
            # No PK => store all fields
            @primary_key_name = nil
            @primary_key_value = nil
            @all_fields = object.attributes
          elsif pk_columns.size == 1
            @primary_key_name = pk_columns.first
            @primary_key_value = object.send(@primary_key_name)
          else
            # Multi PK
            @primary_key_name = pk_columns
            @primary_key_value = pk_columns.map { |col| object.send(col) }
          end
        end
      else
        # No object => we are presumably deserializing from a hash
        @database = options[:database]
        @table = options[:table]
        @operation = (options[:operation] || "u").to_s.first
        @primary_key_name = options[:primary_key_name]
        @primary_key_value = options[:primary_key_value]
        @all_fields = options[:all_fields]
        @record = nil
      end
    end

    def field_changed?(field)
      changes.key?(field.to_s)
    end

    def changed_fields
      changes.keys
    end

    def old_value_for(field)
      changes[field.to_s].first
    end

    def new_value_for(field)
      changes[field.to_s].last
    end

    def infer_klass_from_table_name
      # Loop through all descendants of ActiveRecord::Base to find the class with the matching table name.
      ActiveRecord::Base.descendants.find { |m| m.table_name == table }
    end

    def record
      @record ||= find_record
    end

    def find_record
      klass = infer_klass_from_table_name
      return unless klass

      if primary_key_name.nil?
        klass.find_by(**all_fields)
      elsif primary_key_name.is_a?(Array)
        conditions = {}
        primary_key_name.each_with_index do |col, index|
          conditions[col] = primary_key_value[index]
        end
        klass.find_by(conditions)
      else
        klass.find_by(primary_key_name => primary_key_value)
      end
    end

    def as_hash
      result = {
        database: database,
        table: table,
        primary_key_name: primary_key_name,
        primary_key_value: primary_key_value,
        operation: operation,
        changes: changes,
        publisher: HallMonitor.config.publisher_name,
        account_id: Current&.account&.id
      }

      result[:all_fields] = all_fields if primary_key_name.nil?

      result
    end
  end
end
