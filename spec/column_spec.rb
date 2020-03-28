require "spec_helper"

describe Tabulo::Column do
  subject do
    Tabulo::Column.new(
      align_body: :left,
      align_header: :left,
      extractor: extractor,
      formatter: -> (n) { "%.2f" % n },
      header: "X10",
      header_styler: nil,
      index: 3,
      padding_character: " ",
      styler: nil,
      truncation_indicator: "~",
      width: 10)
  end

  let(:extractor) { -> (n) { n * 10 } }

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
    let(:row_index) { 2 }
    let(:column_index) { 5 }

    it "returns a new Cell initialized with the value returned by calling the extractor on the passed source" do
      cell = subject.body_cell(3, row_index: row_index, column_index: column_index)
      expect(cell.instance_variable_get(:@value)).to eq(30)
    end

    it "returns a new Cell which formats its content using the formatter with which the Column was initialized" do
      expect(subject.body_cell(3, row_index: row_index, column_index: column_index).formatted_content).to eq("30.00")
    end
  end

  describe "#body_cell_value" do
    context "when the extractor takes 1 parameter" do
      let(:extractor) { -> (n) { n * 10 } }

      it "returns the underlying value in this column for the passed source item" do
        expect(subject.body_cell_value(3, row_index: 1, column_index: 5)).to eq(30)
      end
    end

    context "when the extractor takes 2 parameters" do
      let(:extractor) { -> (n, row_index) { row_index } }

      it "returns the underlying value in this column for the passed source item" do
        expect(subject.body_cell_value(3, row_index: 1, column_index: 5)).to eq(1)
      end
    end
  end
end
