require "spec_helper"

describe Tabulo::Util do
  describe "slice_hash" do
    it "returns a new hash that's like the original hash but contains only the keys passed, in the "\
      "order passed, but does not include keys not in the original hash" do
      original_hash = { hello: 1, good: 2, morning: 3 }
      new_hash = Tabulo::Util.slice_hash(original_hash, :morning, :hello, :cool)
      expected_hash = { morning: 3, hello: 1 }
      expect(new_hash).to eq(expected_hash)
    end
  end
end
