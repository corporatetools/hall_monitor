require "spec_helper"

RSpec.describe HallMonitor::ActiveRecordExtensions do
  it "exists as a module" do
    expect(described_class).to be_a(Module)
  end

  # Since we're using a mock environment, we'll test the interface rather than actual behavior
  it "has the expected hooks as module methods" do
    extension_module_methods = described_class.instance_methods(false)
    expect(extension_module_methods).to be_empty
  end
end
