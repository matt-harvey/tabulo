require "spec_helper"

describe Tabulo::VERSION do

  it "has semver form" do
    expect(Tabulo::VERSION).to match(/\d+\.\d+\.\d+$/)
  end
end
