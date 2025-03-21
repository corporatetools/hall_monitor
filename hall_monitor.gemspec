require_relative "lib/hall_monitor/version"

Gem::Specification.new do |spec|
  spec.name = "hall_monitor"
  spec.version = HallMonitor::VERSION
  spec.authors = ["Daniel Dailey"]
  spec.email = ["daniel@danieldailey.com"]

  spec.summary = "Database-triggered event system for Rails applications"
  spec.description = "HallMonitor is a database-triggered event system for Rails applications. " \
                     "It allows developers to register reactive code blocks that execute automatically when " \
                     "specific data changes occur."
  spec.homepage = "https://github.com/corporatetools/hall_monitor"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies (deliberately generous versions to work in various environments)
  spec.add_dependency "activerecord", ">= 5.2", "< 8.0"
  spec.add_dependency "activesupport", ">= 5.2", "< 8.0"

  # Development dependencies are now primarily specified in the Gemfile
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  # We'll let the Gemfile control the specific SQLite version
  spec.add_development_dependency "standardrb", "~> 1.0"
end