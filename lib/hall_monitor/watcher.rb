module HallMonitor
  class Watcher
    attr_reader :field_map, :operations, :callback

    def initialize(field_map:, callback:, operations: nil)
      @field_map = HallMonitor::FieldMap.build(field_map)
      @operations = operations&.map(&:to_sym) # normalize
      @callback = callback
    end

    def execute_if_interested(data_change)
      return unless interested_in?(data_change)
      callback.call(data_change)
    rescue => e
      # Use a safe logger approach that works in both Rails and non-Rails environments
      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger.error("[HallMonitor] Watcher encountered an error: #{e.message}")
      else
        puts "[HallMonitor] Watcher encountered an error: #{e.message}"
      end
      raise e
    end

    def interested_in?(data_change)
      return false if operations && !operations.include?(data_change_operation(data_change))
      field_map.overlaps_with?(data_change.table => data_change.changed_fields)
    end

    private

    def data_change_operation(data_change)
      case data_change.operation
      when "c" then :create
      when "u" then :update
      when "d" then :destroy
      else
        :unknown
      end
    end
  end
end
