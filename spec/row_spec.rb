require "spec_helper"

describe Tabulo::Row do

  let!(:table) do
    Tabulo::Table.new(1..5) do |t|
      t.add_column("N") { |n| n }
      t.add_column("Doubled") { |n| n * 2 }
    end
  end

  let(:row) do
    Tabulo::Row.new(table, 3, with_header: with_header)
  end

  let(:with_header) { [true, false].sample }

  it "is an Enumerable" do
    expect(row).to be_a(Enumerable)
    expect(row).to respond_to(:each)
    expect(row).to respond_to(:map)
    expect(row).to respond_to(:to_a)
  end

  describe "#initialize" do
    it "creates a Tabulo::Row" do
      expect(row).to be_a(Tabulo::Row)
    end
  end

  describe "#each" do
    it "iterates once for each column in the table" do
      i = 0
      row.each do |cell|
        i += 1
      end
      expect(i).to eq(2)
    end

    it "iterates over the results of calling the column's extractor on the source object",
      :aggregate_failures do

      row.each_with_index do |cell, i|
        expect(cell).to be_a(Tabulo::Cell)

        case i
        when 0
          expect(cell.value).to eq(3)
        when 1
          expect(cell.value).to eq(6)
        end
      end
    end
  end

  describe "#to_s" do
    context "when row was initialized with `with_header: true`" do
      let(:with_header) { true }

      it "returns a string showing the column headers and the row contents" do
        expect(row.to_s).to eq \
          %q(+--------------+--------------+
             |       N      |    Doubled   |
             +--------------+--------------+
             |            3 |            6 |).gsub(/^ +/, "")
      end
    end

    context "when row was initialized with `with_header: false`" do
      let(:with_header) { false }

      it "returns a string showing the row contents without the column headers" do
        expect(row.to_s).to eq("|            3 |            6 |")
      end
    end

    context "when the table does not have any columns" do
      it "returns an empty string" do
        table = Tabulo::Table.new(0...10)
        row = table.first
        expect(row.to_s).to eq("")
      end
    end
  end

  describe "#to_h" do
    let!(:table) do
      Tabulo::Table.new(0..3) do |t|
        t.add_column("Number") { |n| n }
        t.add_column(:Doubled) { |n| n * 2 }
        t.add_column(2) { |n| 5.8 }
      end
    end

    it "returns a Hash mapping from column labels to Cells, with keys being Symbols or Integers" do
      hash = row.to_h
      expect(hash.keys).to eq([:Number, :Doubled, 2])
      expect(hash.values.map(&:value)).to eq([3, 6, 5.8])
      expect(hash.values.map(&:class).uniq).to eq([Tabulo::Cell])
    end
  end
end
