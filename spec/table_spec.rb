require "spec_helper"

describe Tabulator::Table do

  let(:table) do
    Tabulator::Table.new(1..5) do |t|
      t.add_column("N", &:itself)
      t.add_column("Doubled") { |n| n * 2 }
    end
  end

  pending "#initialize"
  pending "#add_column"

  describe "#to_s" do
    it "returns a string displaying formatted table" do
      expect(table.to_s).to eq \
        %q(+----------+----------+
           |     N    |  Doubled |
           +----------+----------+
           |        1 |        2 |
           |        2 |        4 |
           |        3 |        6 |
           |        4 |        8 |
           |        5 |       10 |).gsub(/^ +/, "")
    end
  end

  describe "#each" do
    it "iterates once for each row of the table's source data" do
      i = 0
      table.each do |row|
        i += 1
      end
      expect(i).to eq(5)
    end

    it "iterates over instances of Tabulator::Row" do
      table.each do |row|
        expect(row).to be_a(Tabulator::Row)
      end
    end
  end

  describe "#header_row" do
    it "returns a string representing a header row for the table" do
      expect(table.header_row).to eq("|     N    |  Doubled |")
    end
  end

  describe "#horizontal_rule" do
    it "returns a horizontal line made up of dashes, of an appropriate width for the table" do
      expect(table.horizontal_rule).to eq("+----------+----------+")
    end
  end

  pending "#body_row"
  pending "#formatted_body_row"
end
