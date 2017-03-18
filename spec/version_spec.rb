require "spec_helper"

describe Tabulator::VERSION do

  it "has semver form" do
    expect(Tabulator::VERSION).to match(/\d+\.\d+\.\d+$/)
  end
end
