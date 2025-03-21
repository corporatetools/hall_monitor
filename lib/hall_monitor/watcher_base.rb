module HallMonitor
  # Abstract base class that includes WatcherBehavior for convenience.
  # This provides a simple way to create watchers without explicitly including
  # the WatcherBehavior module.
  class WatcherBase
    include ::HallMonitor::WatcherBehavior
  end
end 