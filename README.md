# HallMonitor

HallMonitor is a **database-triggered event system** for Rails applications. It allows developers to register **reactive code blocks** that execute automatically when specific data changes occur. This provides a powerful way to track, filter, and respond to changes in the database without directly modifying business logic.

## Why Use HallMonitor?
- **Automate Workflows**: Run code when certain data changes happen (e.g., update logs, send notifications).
- **Decouple Logic**: Keep event-handling logic separate from models and controllers.
- **Performance Optimized**: Execute code asynchronously outside the main request cycle.
- **Fine-Grained Filtering**: Specify **exactly** what changes should trigger execution.
- **Optional Kafka Integration**: Send structured change events to external systems.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "hall_monitor"
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install hall_monitor
```

## Usage

### Setup

In an initializer (`config/initializers/hall_monitor.rb`):

```ruby
Rails.application.config.to_prepare do
  HallMonitor.configure do |config|
    config.publisher_name = "my-app"
    config.emitter = ->(data_change) {
      # This could publish to Kafka, log changes, etc.
    }
  end

  ActiveRecord::Base.include(HallMonitor::ActiveRecordExtensions)
end
```

### Registering a Watcher

A watcher is a piece of code that gets triggered when database changes occur:

```ruby
watcher = HallMonitor::Watcher.new(
  field_map: { User => :email },
  operations: [:update],
  callback: ->(data_change) { 
    puts "User #{data_change.primary_key_value} changed email from #{data_change.old_value_for(:email)} to #{data_change.new_value_for(:email)}"
  }
)

HallMonitor.register_watcher(watcher)
```

### Monitoring Multiple Fields

```ruby
HallMonitor.register_watcher(
  HallMonitor::Watcher.new(
    field_map: {
      User => [:email, :name],
      Order => :status
    },
    callback: ->(data_change) {
      # Your logic here
    }
  )
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/hall_monitor.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT). 