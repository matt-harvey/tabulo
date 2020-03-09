require "spec_helper"

describe Tabulo::Util do
  describe "multiple_of" do
    it "returns truthy if and only if the first number passed is a factor of the second" do
      aggregate_failures do
        expect(Tabulo::Util.divides?(3, 9)).to be_truthy
        expect(Tabulo::Util.divides?(3, 10)).to be_falsey
        expect(Tabulo::Util.divides?(3, 11)).to be_falsey
        expect(Tabulo::Util.divides?(3, 12)).to be_truthy
        expect(Tabulo::Util.divides?(1, 12)).to be_truthy
        expect(Tabulo::Util.divides?(10, 100)).to be_truthy
        expect(Tabulo::Util.divides?(10, 1000)).to be_truthy
        expect(Tabulo::Util.divides?(5, 1001)).to be_falsey
      end
    end
  end

  describe "max" do
    it "returns the larger of the two numbers passed" do
      aggregate_failures do
        expect(Tabulo::Util.max(3, 5)).to eq(5)
        expect(Tabulo::Util.max(30, 30)).to eq(30)
        expect(Tabulo::Util.max(-4, 3)).to eq(3)
        expect(Tabulo::Util.max(-4, 0)).to eq(0)
        expect(Tabulo::Util.max(4, 10)).to eq(10)
      end
    end
  end

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
