require "spec_helper"

describe Tabulo::Table do

  let(:table) do
    Tabulo::Table.new(1..5, header_frequency: header_frequency) do |t|
      t.add_column("N", &:itself)
      t.add_column("Doubled") { |n| n * 2 }
    end
  end

  let(:header_frequency) { [:start, nil, 5, 20].sample }

  specify "is an Enumerable" do
    expect(table).to be_a(Enumerable)
    expect(table).to respond_to(:each)
    expect(table).to respond_to(:map)
    expect(table).to respond_to(:to_a)
  end

  pending "#initialize"
  pending "#add_column"

  describe "#to_s" do
    context "when table was initialized with `header_frequency: :start`" do
      let(:header_frequency) { :start }

      it "returns a string displaying the formatted table with a header" do
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

    context "when table was initialized with `header_frequency: nil`" do
      let(:header_frequency) { nil }

      it "returns a string displaying the formatted table without a header" do
        expect(table.to_s).to eq \
          %q(|        1 |        2 |
             |        2 |        4 |
             |        3 |        6 |
             |        4 |        8 |
             |        5 |       10 |).gsub(/^ +/, "")
      end
    end

    context "when table was initialized with `header_frequency: <N>`" do
      let(:header_frequency) { 3 }

      it "returns a string displaying the formatted table with header at start and then "\
        "before every Nth row thereafter" do
        expect(table.to_s).to eq \
          %q(+----------+----------+
             |     N    |  Doubled |
             +----------+----------+
             |        1 |        2 |
             |        2 |        4 |
             |        3 |        6 |
             +----------+----------+
             |     N    |  Doubled |
             +----------+----------+
             |        4 |        8 |
             |        5 |       10 |).gsub(/^ +/, "")
      end
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

    it "iterates over instances of Tabulo::Row" do
      table.each do |row|
        expect(row).to be_a(Tabulo::Row)
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

  describe "#formatted_body_row" do
    context "when passed `with_header: true`" do
      it "returns a string representing a row in the body of the table, with a header" do
        expect(table.formatted_body_row(3, with_header: true)).to eq \
          %q(+----------+----------+
             |     N    |  Doubled |
             +----------+----------+
             |        3 |        6 |).gsub(/^ +/, "")
      end
    end

    context "when passed `with_header: false" do
      it "returns a string representing a row in the body of the table, without a header" do
        expect(table.formatted_body_row(3, with_header: false)).to eq("|        3 |        6 |")
      end
    end
  end
end
