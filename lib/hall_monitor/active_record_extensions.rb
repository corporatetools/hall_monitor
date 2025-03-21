module HallMonitor
  module ActiveRecordExtensions
    extend ActiveSupport::Concern

    included do
      after_find :hall_monitor_store_attributes_in_buffer, if: :is_active_record?
      around_save :hall_monitor_capture_comprehensive_changes_around_save, if: :is_active_record?
      around_destroy :hall_monitor_capture_comprehensive_changes_around_destroy, if: :is_active_record?

      after_commit :hall_monitor_emit_changes_after_commit, if: :is_active_record?
      after_rollback :hall_monitor_clear_changes_after_rollback, if: :is_active_record?
    end

    private

    def is_active_record?
      is_a?(ActiveRecord::Base)
    end

    def hall_monitor_store_attributes_in_buffer
      @hall_monitor_buffered_attributes = attributes.deep_dup
    end

    def hall_monitor_buffered_attributes
      @hall_monitor_buffered_attributes || {}
    end

    def hall_monitor_reset_buffered_attributes
      @hall_monitor_buffered_attributes = nil
    end

    def hall_monitor_capture_comprehensive_changes_around_save
      @hall_monitor_operation ||= new_record? ? :create : :update

      yield

      new_attrs = attributes.deep_dup
      old_attrs = hall_monitor_buffered_attributes
      operation = @hall_monitor_operation

      changes_hash = build_attribute_diff(old_attrs, new_attrs)

      transaction_changes << ::HallMonitor::DataChange.new(
        object: self,
        operation: operation,
        changes: changes_hash
      )

      hall_monitor_store_attributes_in_buffer
      @hall_monitor_operation = nil
    end

    def hall_monitor_capture_comprehensive_changes_around_destroy
      old_attrs = hall_monitor_store_attributes_in_buffer

      yield

      changes_hash = old_attrs.transform_values { |val| [val, nil] }

      transaction_changes << ::HallMonitor::DataChange.new(
        object: self,
        operation: :destroy,
        changes: changes_hash
      )

      hall_monitor_reset_buffered_attributes
    end

    def hall_monitor_emit_changes_after_commit
      while (data_change = transaction_changes.shift)
        HallMonitor.emit_data_change(data_change)
      end
      transaction_changes.clear
    end

    # Clear buffered changes if a transaction rolls back.
    def hall_monitor_clear_changes_after_rollback
      transaction_changes.clear if ActiveRecord::Base.connection.open_transactions.zero?
    end

    def build_attribute_diff(old_attrs, new_attrs)
      all_keys = old_attrs.keys | new_attrs.keys
      all_keys.each_with_object({}) do |key, diff|
        old_val = old_attrs[key]
        new_val = new_attrs[key]
        diff[key] = [old_val, new_val] if old_val != new_val
      end
    end

    # Thread-local storage for transaction changes to ensure thread safety.
    def transaction_changes
      Thread.current[:hall_monitor_transaction_changes] ||= []
    end
  end
end
