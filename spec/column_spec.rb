require "spec_helper"

describe Tabulo::Column do
  let(:column) do
    Tabulo::Column.new(
      header: "X10",
      width: 10,
      align_header: :left,
      align_body: :left,
      formatter: -> (n) { "%.2f" % n },
      extractor: -> (n) { n * 10 }
    )
  end

  describe "#initialize" do
    it "create a Column" do
      expect(column).to be_a(Tabulo::Column)
    end
  end

  describe "#header_subcells" do
    it 'returns an array of strings representing the components (one per wrapped "subrow") of the '\
      'header cell for this column including internal padding' do
      expect(column.header_subcells).to eq(["X10       "])
    end
  end

  describe "#horizontal_rule" do
    it "returns a horizontal line of dashes matching the width of the column including internal padding" do
      expect(column.horizontal_rule).to eq("----------")
    end
  end

  describe "#body_subcells" do
    it 'returns an array of strings representing the components (one per wrapped "subrow") of the '\
      'body cell for this column for the passed source item, including internal padding' do
      expect(column.body_subcells(3)).to eq(["30.00     "])
    end
  end

  describe "#formatted_cell_content" do
    it "returns a string being to formatted content for this column for the passed source item, "\
      "without internal padding" do
      expect(column.formatted_cell_content(3)).to eq("30.00")
    end
  end

  describe "#body_cell_value" do
    it "returns the underlying value in this column for the passed source item" do
      expect(column.body_cell_value(3)).to eq(30)
    end
  end
end
