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

  pending "#each"
  pending "#header_row"
  pending "#horizontal_rule"
  pending "#body_row"
  pending "#formatted_body_row"
end
