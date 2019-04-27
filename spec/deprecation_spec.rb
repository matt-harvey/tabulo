require "spec_helper"

describe Tabulo::Deprecation do

  describe "without_warnings" do
    it "disables deprecation warnings within the passed block" do
      expect(Kernel).not_to receive(:warn)

      Tabulo::Deprecation.without_warnings do
        Tabulo::Deprecation.warn("`old_func'", "`new_func'", 1)
      end
    end
  end

  describe '.warn' do
    it "calls Kernel.warn with a message detailing the call site, the thing that's deprecated, and its replacement" do
      kaller = double("caller")
      allow(Kernel).to receive(:caller).and_return(kaller)
      allow(kaller).to receive(:[]).with(3).and_return "some_file.rb:30:in `some func'"
      expect(Kernel).to receive(:warn).
        with("some_file.rb:30:in `some func': [DEPRECATION] `old_func' is deprecated. Please use `new_func' instead.")

      Tabulo::Deprecation.warn("`old_func'", "`new_func'", 3)
    end
  end
end
