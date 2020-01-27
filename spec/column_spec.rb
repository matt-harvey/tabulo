require "spec_helper"

describe Tabulo::Column do
  subject do
    Tabulo::Column.new(
      align_body: :left,
      align_header: :left,
      extractor: -> (n) { n * 10 },
      formatter: -> (n) { "%.2f" % n },
      header: "X10",
      header_styler: nil,
      padding_character: " ",
      styler: nil,
      truncation_indicator: "~",
      width: 10)
  end

  describe "#initialize" do
    it "create a Column" do
      is_expected.to be_a(Tabulo::Column)
    end
  end

  describe "#header_cell" do
    it "returns a new Cell initialized with the header content" do
      expect(subject.header_cell.instance_variable_get(:@value)).to eq("X10")
    end
  end

  describe "#body_cell" do
    it "returns a new Cell initialized with the value returned by calling the extractor on the passed source" do
      expect(subject.body_cell(3).instance_variable_get(:@value)).to eq(30)
    end

    it "returns a new Cell which formats its content using the formatter with which the Column was initialized" do
      expect(subject.body_cell(3).formatted_content).to eq("30.00")
    end
  end

  describe "#body_cell_value" do
    it "returns the underlying value in this column for the passed source item" do
      expect(subject.body_cell_value(3)).to eq(30)
    end
  end
end
