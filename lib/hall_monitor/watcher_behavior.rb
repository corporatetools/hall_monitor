module HallMonitor
  # Provides a DSL for defining watchers in a clean, declarative way.
  # Can be included in any class to add watcher functionality.
  module WatcherBehavior
    extend ActiveSupport::Concern

    class_methods do
      # Defines what changes to watch for.
      # Supports multiple forms:
      #   react_to_changes_on Company, with: :do_something
      #   react_to_changes_on Company, with: :do_something, only: [:create, :destroy]
      #   react_to_changes_on Company, with: :do_something, only: :create
      #   react_to_changes_on Company, with: :do_something, except: [:update]
      #   react_to_changes_on Company, with: :do_something, except: :update
      #   react_to_changes_on Company, [:field1, :field2], only: [:create, :destroy] do |data_change|
      #   react_to_changes_on Company, [:field1, :field2], only: [:create, :destroy], with: ->(data_change) do
      #   react_to_changes_on { Company => [:field1, :field2], Registration }, with: :do_something
      #   react_to_changes_on HallMonitor::FieldMap.new(...), with: :do_something
      #   react_to_changes_on "users", with: :do_something
      #   react_to_changes_on :users, with: :do_something
      #
      # @param field_map_or_table_name [Object] The field map or table to watch
      # @param field_names [Array<Symbol>, nil] Optional list of fields to watch
      # @param options [Hash] Additional options including :only, :except, and :with
      # @param block [Proc] Optional block to use as callback
      # @return [self] Returns self for method chaining
      def react_to_changes_on(field_map_or_table_name = nil, field_names = nil, **options, &block)
        @field_map = field_names ? { field_map_or_table_name => field_names } : field_map_or_table_name
        @operations = _hmwb_determine_operations(options)
        @callback = if options[:with]
          options[:with].is_a?(Symbol) ? method(options[:with]) : options[:with]
        elsif block
          block
        end

        _hmwb_register_watcher if @callback
        self
      end

      private

      def _hmwb_field_map
        @field_map
      end

      def _hmwb_operations
        @operations
      end

      def _hmwb_callback
        @callback
      end

      def _hmwb_determine_operations(options)
        if options[:only]
          Array(options[:only]).map(&:to_sym)
        elsif options[:except]
          all_operations = [:create, :update, :destroy]
          excluded = Array(options[:except]).map(&:to_sym)
          all_operations - excluded
        else
          nil
        end
      end

      def _hmwb_register_watcher
        return unless _hmwb_field_map && _hmwb_callback

        HallMonitor.register_watcher(
          HallMonitor::Watcher.new(
            field_map: _hmwb_field_map,
            operations: _hmwb_operations,
            callback: _hmwb_callback
          )
        )
      end
    end
  end
end 