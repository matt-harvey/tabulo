require "spec_helper"

describe Tabulo::Cell do
  let(:cell) do
    Tabulo::Cell.new(
      value: value,
      formatter: formatter,
      alignment: :right,
      width: 6,
      styler: styler,
      truncation_indicator: ".",
      padding_character: " ")
  end

  let(:value) { 30 }
  let(:formatter) { -> (source) { source.to_s } }
  let(:styler) { -> (source, str) { str } }

  describe "#height" do
    subject { cell.height }
    before { allow(cell).to receive(:subcells).and_return(["a", "b", "c"]) }

    it "returns the number of subcells in the cell" do
      is_expected.to eq(3)
    end
  end

  describe "#padded_truncated_subcells" do
    subject { cell.padded_truncated_subcells(target_height, 2) }
    let(:value) { "ab\ncde\nfg" }

    context "when the target height is greater than required to contain the wrapped cell content" do
      let(:target_height) { 5 }

      it "returns an array of strings each representing the part of the cell occurring on a different line, "\
        "plus a number of blank lines to bring the total up the the target height, with total width equal to "\
        "cell width plus the specified amount of extra padding on either side" do
        is_expected.to eq(
          [
            "      ab  ",
            "     cde  ",
            "      fg  ",
            "          ",
            "          ",
          ])
      end
    end

    context "when the target height is just enough to contain the wrapped cell content" do
      let(:target_height) { 3 }

      it "returns an array of strings each representing the part of the cell occurring on a different line, "\
        "with total width equal to cell width plus the specified amount of extra padding on either side" do
        is_expected.to eq(
          [
            "      ab  ",
            "     cde  ",
            "      fg  ",
          ])
      end
    end

    context "when the target height is less than required to contain the wrapped cell content" do
      let(:target_height) { 2 }

      it "returns an array of strings each representing the part of the cell occurring on a different line, "\
        "truncated to the target height, with total width equal to cell width plus the specified amount of "\
        "extra padding on either side" do
        is_expected.to eq(
          [
            "      ab  ",
            "     cde. ",
          ])
      end
    end
  end

  describe "#formatted_content" do
    subject { cell.formatted_content }
    let(:formatter) { -> (n) { "%.3f" % n } }

    it "returns the result of calling the Cell's formatter on its value" do
      is_expected.to eq("30.000")
    end
  end
end
