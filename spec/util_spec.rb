require "spec_helper"

describe Tabulo::Util do

  describe "condense_lines" do
    it "joins lines with a newline character, after removing the empty ones" do
      lines = ["Hello, my name is", "", "", "Max,", "", "how are you?"]
      expect(Tabulo::Util.condense_lines(lines)).to eq \
        %q(Hello, my name is
           Max,
           how are you?).gsub(/^ +/, "")
    end
  end

  describe "divides" do
    it "returns truthy if and only if the first number passed is a factor of the second" do
      aggregate_failures do
        expect(Tabulo::Util.divides?(3, 9)).to be_truthy
        expect(Tabulo::Util.divides?(3, 10)).to be_falsey
        expect(Tabulo::Util.divides?(3, 0)).to be_truthy
        expect(Tabulo::Util.divides?(3, 11)).to be_falsey
        expect(Tabulo::Util.divides?(3, 12)).to be_truthy
        expect(Tabulo::Util.divides?(1, 12)).to be_truthy
        expect(Tabulo::Util.divides?(10, 100)).to be_truthy
        expect(Tabulo::Util.divides?(10, 1000)).to be_truthy
        expect(Tabulo::Util.divides?(5, 1001)).to be_falsey
      end
    end
  end

  describe "join_lines" do
    it "joins lines with a newline character" do
      lines = ["Hello, my name is", "Max,", "how are you?"]
      expect(Tabulo::Util.join_lines(lines)).to eq \
        %q(Hello, my name is
           Max,
           how are you?).gsub(/^ +/, "")
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

  describe "wrapped_width" do
    it "returns the length of the longest segment of str when split by newlines" do
      str0 = "alsdkfj#{$/}lask#{$/}asdjhjhkjl;kh#{$/}#{$/}asdf"
      str1 = ""
      str2 = "alsdf"
      expect(Tabulo::Util.wrapped_width(str0)).to eq(13)
      expect(Tabulo::Util.wrapped_width(str1)).to eq(0)
      expect(Tabulo::Util.wrapped_width(str2)).to eq(5)
    end
  end
end
