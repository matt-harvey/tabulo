require "spec_helper"

describe Tabulo::Table do

  around(:all) do |group|
    Tabulo::Deprecation.without_warnings { group.run }
  end

  let(:table) do
    Tabulo::Table.new(
      source,
      column_width: column_width,
      header_frequency: header_frequency,
      wrap_header_cells_to: wrap_header_cells_to,
      wrap_body_cells_to: wrap_body_cells_to,
      horizontal_rule_character: horizontal_rule_character,
      vertical_rule_character: vertical_rule_character,
      intersection_character: intersection_character,
      truncation_indicator: truncation_indicator,
      column_padding: column_padding
    ) do |t|
      t.add_column("N") { |n| n }
      t.add_column("Doubled") { |n| n * 2 }
    end
  end

  let(:source) { 1..5 }
  let(:column_width) { nil }
  let(:header_frequency) { :start }
  let(:wrap_header_cells_to) { nil }
  let(:wrap_body_cells_to) { nil }
  let(:horizontal_rule_character) { nil }
  let(:vertical_rule_character) { nil }
  let(:intersection_character) { nil }
  let(:truncation_indicator) { nil }
  let(:column_padding) { nil }

  it "is an Enumerable" do
    expect(table).to be_a(Enumerable)
    expect(table).to respond_to(:each)
    expect(table).to respond_to(:map)
    expect(table).to respond_to(:to_a)
  end

  describe "#initialize / #to_s" do
    describe "`cols` param" do
      it "accepts symbols corresponding to methods on the source objects" do
        expect(Tabulo::Table.new([1, 2, 3], :to_i, :to_f).to_s).to eq \
          %q(+--------------+--------------+
             |     to_i     |     to_f     |
             +--------------+--------------+
             |            1 |          1.0 |
             |            2 |          2.0 |
             |            3 |          3.0 |).gsub(/^ +/, "")
      end

      it "raises Tabulo::InvalidColumnLabelError if symbols are not unique" do
        expect { Tabulo::Table.new([1, 2, 3], :to_i, :to_i) }.to \
          raise_error(Tabulo::InvalidColumnLabelError)
      end

      it "does not issue a deprecation warning" do
        expect(Tabulo::Deprecation).not_to receive(:warn)

        Tabulo::Table.new([1, 2, 3], :to_i, :to_s)
      end
    end

    describe "`columns` param" do
      it "accepts symbols corresponding to methods on the source objects" do
        expect(Tabulo::Table.new([1, 2, 3], columns: [:to_i, :to_f]).to_s).to eq \
          %q(+--------------+--------------+
             |     to_i     |     to_f     |
             +--------------+--------------+
             |            1 |          1.0 |
             |            2 |          2.0 |
             |            3 |          3.0 |).gsub(/^ +/, "")
      end

      it "raises Tabulo::InvalidColumnLabelError if symbols are not unique" do
        expect { Tabulo::Table.new([1, 2, 3], columns: [:to_i, :to_i]) }.to \
          raise_error(Tabulo::InvalidColumnLabelError)
      end

      it "issues a deprecation warning" do
        expect(Tabulo::Deprecation).to receive(:warn).
          with("`columns' option to Tabulo::Table#initialize", "the variable length parameter `cols'", 2)

        Tabulo::Table.new([1, 2, 3], columns: [:to_i, :to_s])
      end
    end

    describe "`header_frequency` param" do
      context "when table is initialized with `header_frequency: :start`" do
        let(:header_frequency) { :start }

        it "initializes a table displaying the formatted table with a header" do
          expect(table).to be_a(Tabulo::Table)
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when table is initialized with `header_frequency: nil`" do
        let(:header_frequency) { nil }

        it "initializes a table displaying the formatted table without a header" do
          expect(table).to be_a(Tabulo::Table)
          expect(table.to_s).to eq \
            %q(|            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when table is initialized with `header_frequency: <N>`" do
        let(:header_frequency) { 3 }

        it "initializes a table displaying the formatted table with header at start and then "\
          "before every Nth row thereafter" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               +--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when the table doesn't have any columns" do
        specify "#to_s returns an empty string" do
          table = Tabulo::Table.new(0..10)
          expect(table.to_s).to eq("")
        end
      end
    end

    describe "`wrap_header_cells_to` param" do
      before(:each) { table.add_column("N" * 26, &:to_i) }

      context "when table is initialized with `wrap_header_cells_to: nil`" do
        let(:wrap_header_cells_to) { nil }

        it "wraps header cell contents as necessary if they exceed the column width" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+--------------+
               |       N      |    Doubled   | NNNNNNNNNNNN |
               |              |              | NNNNNNNNNNNN |
               |              |              |      NN      |
               +--------------+--------------+--------------+
               |            1 |            2 |            1 |
               |            2 |            4 |            2 |
               |            3 |            6 |            3 |
               |            4 |            8 |            4 |
               |            5 |           10 |            5 |).gsub(/^ +/, "")
        end
      end

      context "when table is initialized with `wrap_header_cells_to: <N>`" do
        context "when N rows are insufficient to accommodate the header content" do
          let(:wrap_header_cells_to) { 2 }

          it "truncates header cell contents to N subrows, instead of wrapping them indefinitely, "\
            "and shows a truncation indicator" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+--------------+
                 |       N      |    Doubled   | NNNNNNNNNNNN |
                 |              |              | NNNNNNNNNNNN~|
                 +--------------+--------------+--------------+
                 |            1 |            2 |            1 |
                 |            2 |            4 |            2 |
                 |            3 |            6 |            3 |
                 |            4 |            8 |            4 |
                 |            5 |           10 |            5 |).gsub(/^ +/, "")
          end
        end

        context "when N rows are insufficient to accommodate the header content and padding is 0" do
          let(:wrap_header_cells_to) { 2 }
          let(:column_padding) { 0 }

          it "truncates header cell contents to N subrows, instead of wrapping them indefinitely, "\
            "but does not show a truncation indicator" do
            expect(table.to_s).to eq \
              %q(+------------+------------+------------+
                 |      N     |   Doubled  |NNNNNNNNNNNN|
                 |            |            |NNNNNNNNNNNN|
                 +------------+------------+------------+
                 |           1|           2|           1|
                 |           2|           4|           2|
                 |           3|           6|           3|
                 |           4|           8|           4|
                 |           5|          10|           5|).gsub(/^ +/, "")
          end
        end

        context "when N rows are insufficient to accommodate the header content and padding > 1" do
          let(:wrap_header_cells_to) { 2 }
          let(:column_padding) { 2 }

          it "truncates header cell contents to N subrows, instead of wrapping them indefinitely, "\
            "and shows a single truncation indicator within the padded content" do
            expect(table.to_s).to eq \
              %q(+----------------+----------------+----------------+
                 |        N       |     Doubled    |  NNNNNNNNNNNN  |
                 |                |                |  NNNNNNNNNNNN~ |
                 +----------------+----------------+----------------+
                 |             1  |             2  |             1  |
                 |             2  |             4  |             2  |
                 |             3  |             6  |             3  |
                 |             4  |             8  |             4  |
                 |             5  |            10  |             5  |).gsub(/^ +/, "")
          end
        end

        context "when N rows are just insufficient to accommodate the header content" do
          let(:wrap_header_cells_to) { 3 }

          it "does not truncate the header cells and does not show a truncation indicator" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+--------------+
                 |       N      |    Doubled   | NNNNNNNNNNNN |
                 |              |              | NNNNNNNNNNNN |
                 |              |              |      NN      |
                 +--------------+--------------+--------------+
                 |            1 |            2 |            1 |
                 |            2 |            4 |            2 |
                 |            3 |            6 |            3 |
                 |            4 |            8 |            4 |
                 |            5 |           10 |            5 |).gsub(/^ +/, "")
          end
        end

        context "when N rows are more than sufficient to accommodate the header content" do
          let(:wrap_header_cells_to) { 4 }

          it 'only produces the number of "subrows" that are necessary to accommodate the contents, '\
            'and does not show a truncation indicator' do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+--------------+
                 |       N      |    Doubled   | NNNNNNNNNNNN |
                 |              |              | NNNNNNNNNNNN |
                 |              |              |      NN      |
                 +--------------+--------------+--------------+
                 |            1 |            2 |            1 |
                 |            2 |            4 |            2 |
                 |            3 |            6 |            3 |
                 |            4 |            8 |            4 |
                 |            5 |           10 |            5 |).gsub(/^ +/, "")
          end
        end
      end
    end

    describe "`wrap_body_cells_to` param" do
      let(:source) { [1, 2, 500_000_000_000] }
      let(:wrap_body_cells_to) { nil }

      context "when table is initialized with `wrap_body_cells_to: nil`" do
        let(:wrap_body_cells_to) { nil }

        it "wraps cell contents as necessary if they exceed the column width" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               | 500000000000 | 100000000000 |
               |              |            0 |).gsub(/^ +/, "")
        end
      end

      context "when table is initialized with `wrap_body_cells_to: <N>`" do
        context "when N is insufficient to accommodate the cell content" do
          let(:wrap_body_cells_to) { 1 }

          it "truncates body cell contents to N subrows, instead of wrapping them indefinitely" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+
                 |       N      |    Doubled   |
                 +--------------+--------------+
                 |            1 |            2 |
                 |            2 |            4 |
                 | 500000000000 | 100000000000~|).gsub(/^ +/, "")
          end
        end

        context "when N is just sufficient to accommodate the cell content" do
          let(:wrap_body_cells_to) { 2 }

          it "does not truncate the cell content, and does not show a truncation indicator" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+
                 |       N      |    Doubled   |
                 +--------------+--------------+
                 |            1 |            2 |
                 |            2 |            4 |
                 | 500000000000 | 100000000000 |
                 |              |            0 |).gsub(/^ +/, "")
          end
        end

        context "when N is more than sufficient to accommodate the cell content" do
          let(:wrap_body_cells_to) { 3 }

          it "does not truncate the cell content, does not show a truncation indicator, and "\
            "produces only just enough subrows to accommodate the content" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+
                 |       N      |    Doubled   |
                 +--------------+--------------+
                 |            1 |            2 |
                 |            2 |            4 |
                 | 500000000000 | 100000000000 |
                 |              |            0 |).gsub(/^ +/, "")
          end
        end

        context "when N is more than sufficient to accommodate the cell content, and column_padding is > 1" do
          let(:wrap_body_cells_to) { 3 }
          let(:column_padding) { 2 }

          it "does not truncate the cell content, does not show a truncation indicator, and "\
            "produces only just enough subrows to accommodate the content, with column_padding respected" do
            expect(table.to_s).to eq \
              %q(+----------------+----------------+
                 |        N       |     Doubled    |
                 +----------------+----------------+
                 |             1  |             2  |
                 |             2  |             4  |
                 |  500000000000  |  100000000000  |
                 |                |             0  |).gsub(/^ +/, "")
          end
        end
      end
    end

    describe "`column_width` param" do
      context "if not specified or passed nil" do
        it "defaults to 12" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when passed an Integer" do
        let(:column_width) { 9 }

        it "causes all column widths to default to the given Integer, unless overridden for "\
          "particular columns" do
          table.add_column(:even?, width: 5)
          expect(table.to_s).to eq \
            %q(+-----------+-----------+-------+
               |     N     |  Doubled  | even? |
               +-----------+-----------+-------+
               |         1 |         2 | false |
               |         2 |         4 |  true |
               |         3 |         6 | false |
               |         4 |         8 |  true |
               |         5 |        10 | false |).gsub(/^ +/, "")
        end
      end
    end

    context "when there are multibyte characters in the headers or body cell contents" do
      it "calculates widths and aligns content correctly" do
        table = Tabulo::Table.new(1..3) do |t|
          t.add_column("Something") { |n| "很酷的时候" }
          t.add_column("很酷的时") { |n| n * 2 }
        end

        expect(table.to_s).to eq \
          %q(+--------------+--------------+
             |   Something  |   很酷的时   |
             +--------------+--------------+
             | 很酷的时候   |            2 |
             | 很酷的时候   |            4 |
             | 很酷的时候   |            6 |).gsub(/^ +/, "")
      end

      it "wraps content correctly" do
        table = Tabulo::Table.new(1..2) do |t|
          t.add_column("很\n酷") { |n| "很酷的时候很酷的时候" }
          t.add_column("很酷的时候很酷的时候很酷的时候") { |n| n * 2 }
        end

        expect(table.to_s).to eq \
          %q(+--------------+--------------+
             |      很      | 很酷的时候很 |
             |      酷      | 酷的时候很酷 |
             |              |    的时候    |
             +--------------+--------------+
             | 很酷的时候很 |            2 |
             | 酷的时候     |              |
             | 很酷的时候很 |            4 |
             | 酷的时候     |              |).gsub(/^ +/, "")
      end
    end

    context "when there are newlines in headers or body cell contents" do
      context "with unlimited wrapping" do
        it "respects newlines within header and cells" do
          table = Tabulo::Table.new(["Two\nlines", "\nInitial", "Final\n", "Multiple\nnew\nlines"]) do |t|
            t.add_column(:itself, header: "Firstpart\nsecondpart", width: 7) { |s| s }
            t.add_column(:length)
            t.add_column("Lines\nin\nheader", align_body: :right) { |s| s }
          end

          expect(table.to_s).to eq \
            %q(+---------+--------------+--------------+
               | Firstpa |    length    |     Lines    |
               |    rt   |              |      in      |
               | secondp |              |    header    |
               |   art   |              |              |
               +---------+--------------+--------------+
               | Two     |            9 |          Two |
               | lines   |              |        lines |
               |         |            8 |              |
               | Initial |              |      Initial |
               | Final   |            6 |        Final |
               |         |              |              |
               | Multipl |           18 |     Multiple |
               | e       |              |          new |
               | new     |              |        lines |
               | lines   |              |              |).gsub(/^ +/, "")

        end
      end

      context "with truncation" do
        it "accounts for newlines within header and cells" do
          table = Tabulo::Table.new(["Two\nlines", "\nInitial", "Final\n", "Multiple\nnew\nlines"],
            wrap_header_cells_to: 2, wrap_body_cells_to: 1) do |t|
            t.add_column(:itself) { |s| s }
            t.add_column(:length)
            t.add_column("Lines\nin\nheader", align_body: :right) { |s| s }
          end

          expect(table.to_s).to eq \
            %q(+--------------+--------------+--------------+
               |    itself    |    length    |     Lines    |
               |              |              |      in     ~|
               +--------------+--------------+--------------+
               | Two         ~|            9 |          Two~|
               |             ~|            8 |             ~|
               | Final       ~|            6 |        Final~|
               | Multiple    ~|           18 |     Multiple~|).gsub(/^ +/, "")
        end
      end
    end

    describe "`horizontal_rule_character` param" do
      context "when passed nil" do
        let(:horizontal_rule_character) { nil }

        it "determines the character used for all horizontal lines in the table (excluding corners), "\
          "defaulting to '-'" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when passed a non-nil character" do
        let(:horizontal_rule_character) { "!" }

        it "causes the character used for all horizontal lines in the table (excluding corners), "\
          "to be that character" do
          expect(table.to_s).to eq \
            %q(+!!!!!!!!!!!!!!+!!!!!!!!!!!!!!+
               |       N      |    Doubled   |
               +!!!!!!!!!!!!!!+!!!!!!!!!!!!!!+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when passed something other than nil or a single-character String" do
        subject do
          Tabulo::Table.new(source, horizontal_rule_character: horizontal_rule_character)
        end

        context "when passed an empty string" do
          let(:horizontal_rule_character) { "" }

          it "raises a Tabulo::InvalidHorizontalRuleCharacterError" do
            expect { subject }.to raise_error(Tabulo::InvalidHorizontalRuleCharacterError)
          end
        end

        context "when passed an string longer than one character" do
          let(:horizontal_rule_character) { "!!" }

          it "raises a Tabulo::InvalidHorizontalRuleCharacterError" do
            expect { subject }.to raise_error(Tabulo::InvalidHorizontalRuleCharacterError)
          end
        end

        context "when passed something other than nil or a String" do
          let(:horizontal_rule_character) { 1 }

          it "raises a Tabulo::InvalidHorizontalRuleCharacterError" do
            expect { subject }.to raise_error(Tabulo::InvalidHorizontalRuleCharacterError)
          end
        end
      end
    end

    describe "`vertical_rule_character` param" do
      context "when passed nil" do
        let(:vertical_rule_character) { nil }

        it "determines the character used for all vertical lines in the table (excluding corners), "\
          "defaulting to '|'" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when passed a non-nil character" do
        let(:vertical_rule_character) { "!" }

        it "causes the character used for all vertical lines in the table (excluding corners), "\
          "to be that character" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               !       N      !    Doubled   !
               +--------------+--------------+
               !            1 !            2 !
               !            2 !            4 !
               !            3 !            6 !
               !            4 !            8 !
               !            5 !           10 !).gsub(/^ +/, "")
        end
      end

      context "when passed something other than nil or a single-character String" do
        subject do
          Tabulo::Table.new(source, vertical_rule_character: vertical_rule_character)
        end

        context "when passed an empty string" do
          let(:vertical_rule_character) { "" }

          it "raises a Tabulo::InvalidVerticalRuleCharacterError" do
            expect { subject }.to raise_error(Tabulo::InvalidVerticalRuleCharacterError)
          end
        end

        context "when passed an string longer than one character" do
          let(:vertical_rule_character) { "!!" }

          it "raises a Tabulo::InvalidVerticalRuleCharacterError" do
            expect { subject }.to raise_error(Tabulo::InvalidVerticalRuleCharacterError)
          end
        end

        context "when passed something other than nil or a String" do
          let(:vertical_rule_character) { 1 }

          it "raises a Tabulo::InvalidVerticalRuleCharacterError" do
            expect { subject }.to raise_error(Tabulo::InvalidVerticalRuleCharacterError)
          end
        end
      end
    end

    describe "`intersection_character` param" do
      context "when passed nil" do
        let(:intersection_character) { nil }

        it "determines the character used for all intersections and corners in the table, "\
          "defaulting to '+'" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when passed a non-nil character" do
        let(:intersection_character) { "*" }

        it "causes the character used for all intersections and corners in the table to be that "\
          "character" do
          expect(table.to_s).to eq \
            %q(*--------------*--------------*
               |       N      |    Doubled   |
               *--------------*--------------*
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when passed something other than nil or a single-character String" do
        subject do
          Tabulo::Table.new(source, intersection_character: intersection_character)
        end

        context "when passed an empty string" do
          let(:intersection_character) { "" }

          it "raises a Tabulo::InvalidIntersectionCharacterError" do
            expect { subject }.to raise_error(Tabulo::InvalidIntersectionCharacterError)
          end
        end

        context "when passed an string longer than one character" do
          let(:intersection_character) { "!!" }

          it "raises a Tabulo::InvalidIntersectionCharacterError" do
            expect { subject }.to raise_error(Tabulo::InvalidIntersectionCharacterError)
          end
        end

        context "when passed something other than nil or a String" do
          let(:intersection_character) { 1 }

          it "raises a Tabulo::InvalidIntersectionCharacterError" do
            expect { subject }.to raise_error(Tabulo::InvalidIntersectionCharacterError)
          end
        end
      end
    end

    describe "`truncation_indicator` param" do
      let(:table) do
        Tabulo::Table.new(
          source,
          wrap_header_cells_to: 1,
          wrap_body_cells_to: 1,
          truncation_indicator: truncation_indicator
        ) do |t|
          t.add_column("N") { |n| n }
          t.add_column("AAAAAAAAAAAAAAAAAAAA") { |n| n * 2 }
        end
      end
      let(:source) { [400000000000000000, 400000000000000001] }

      context "when passed nil" do
        let(:truncation_indicator) { nil }

        it "determines the character used to indicate that a cell's content has been truncated, "\
          "defaulting to '~'" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      | AAAAAAAAAAAA~|
               +--------------+--------------+
               | 400000000000~| 800000000000~|
               | 400000000000~| 800000000000~|).gsub(/^ +/, "")
        end
      end

      context "when passed a non-nil character" do
        let(:truncation_indicator) { "*" }

        it "causes the character used for indicating that a cell's content has been truncated, to be that"\
          "character" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      | AAAAAAAAAAAA*|
               +--------------+--------------+
               | 400000000000*| 800000000000*|
               | 400000000000*| 800000000000*|).gsub(/^ +/, "")
        end
      end

      context "when passed something other than nil or a single-character String" do
        subject do
          Tabulo::Table.new(source, truncation_indicator: truncation_indicator)
        end

        context "when passed an empty string" do
          let(:truncation_indicator) { "" }

          it "raises a Tabulo::InvalidTruncationIndicatorError" do
            expect { subject }.to raise_error(Tabulo::InvalidTruncationIndicatorError)
          end
        end

        context "when passed an string longer than one character" do
          let(:truncation_indicator) { "!!" }

          it "raises a Tabulo::InvalidTruncationIndicatorError" do
            expect { subject }.to raise_error(Tabulo::InvalidTruncationIndicatorError)
          end
        end

        context "when passed something other than nil or a String" do
          let(:truncation_indicator) { 1 }

          it "raises a Tabulo::InvalidTruncationIndicatorError" do
            expect { subject }.to raise_error(Tabulo::InvalidTruncationIndicatorError)
          end
        end
      end
    end

    describe "`column_padding` param" do
      context "by default" do
        it "determines the amount of padding on either side of each column to be 1" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |).gsub(/^ +/, "")
        end
      end

      context "when passed a number greater than 1" do
        let(:column_padding) { 2 }

        it "determines the amount of padding on either side of each column to be that number" do
          expect(table.to_s).to eq \
            %q(+----------------+----------------+
               |        N       |     Doubled    |
               +----------------+----------------+
               |             1  |             2  |
               |             2  |             4  |
               |             3  |             6  |
               |             4  |             8  |
               |             5  |            10  |).gsub(/^ +/, "")
        end
      end

      context "when passed 0" do
        let(:column_padding) { 0 }

        it "causes there to be no padding on either side of each column" do
          expect(table.to_s).to eq \
            %q(+------------+------------+
               |      N     |   Doubled  |
               +------------+------------+
               |           1|           2|
               |           2|           4|
               |           3|           6|
               |           4|           8|
               |           5|          10|).gsub(/^ +/, "")
        end
      end
    end

    describe "`align_header` param" do
      let(:table) do
        Tabulo::Table.new(
          source,
          column_width: column_width,
          header_frequency: header_frequency,
          wrap_header_cells_to: wrap_header_cells_to,
          wrap_body_cells_to: wrap_body_cells_to,
          horizontal_rule_character: horizontal_rule_character,
          vertical_rule_character: vertical_rule_character,
          intersection_character: intersection_character,
          truncation_indicator: truncation_indicator,
          column_padding: column_padding,
          align_header: :left
        ) do |t|
          t.add_column("N") { |n| n }
          t.add_column("Doubled") { |n| n * 2 }
        end
      end

      it "sets the default header alignment for columns in the table" do
        expect(table.to_s).to eq \
          %q(+--------------+--------------+
             | N            | Doubled      |
             +--------------+--------------+
             |            1 |            2 |
             |            2 |            4 |
             |            3 |            6 |
             |            4 |            8 |
             |            5 |           10 |).gsub(/^ +/, "")
      end

      it "sets a default header alignment that can be overriden via #add_column" do
        table.add_column(:even?, header: "Even?", align_header: :right)

        expect(table.to_s).to eq \
          %q(+--------------+--------------+--------------+
             | N            | Doubled      |        Even? |
             +--------------+--------------+--------------+
             |            1 |            2 |     false    |
             |            2 |            4 |     true     |
             |            3 |            6 |     false    |
             |            4 |            8 |     true     |
             |            5 |           10 |     false    |).gsub(/^ +/, "")
      end
    end

    describe "`align_body` param" do
      let(:table) do
        Tabulo::Table.new(
          source,
          column_width: column_width,
          header_frequency: header_frequency,
          wrap_header_cells_to: wrap_header_cells_to,
          wrap_body_cells_to: wrap_body_cells_to,
          horizontal_rule_character: horizontal_rule_character,
          vertical_rule_character: vertical_rule_character,
          intersection_character: intersection_character,
          truncation_indicator: truncation_indicator,
          column_padding: column_padding,
          align_body: :left
        ) do |t|
          t.add_column("N") { |n| n }
          t.add_column("Doubled") { |n| n * 2 }
        end
      end

      it "sets the default body cell alignment for columns in the table" do
        expect(table.to_s).to eq \
          %q(+--------------+--------------+
             |       N      |    Doubled   |
             +--------------+--------------+
             | 1            | 2            |
             | 2            | 4            |
             | 3            | 6            |
             | 4            | 8            |
             | 5            | 10           |).gsub(/^ +/, "")
      end

      it "sets a default body cell alignment that can be overriden via #add_column" do
        table.add_column(:even?, header: "Even?", align_body: :right)

        expect(table.to_s).to eq \
          %q(+--------------+--------------+--------------+
             |       N      |    Doubled   |     Even?    |
             +--------------+--------------+--------------+
             | 1            | 2            |        false |
             | 2            | 4            |         true |
             | 3            | 6            |        false |
             | 4            | 8            |         true |
             | 5            | 10           |        false |).gsub(/^ +/, "")
      end
    end
  end

  describe "#add_column" do
    it "adds to the table's columns" do
      expect { table.add_column(:even?) }.to change { table.column_registry.count }.by(1)
    end

    describe "`header` param" do
      it "sets the column header, independently of the `label` argument" do
        table.add_column(:even?, header: "Armadillo")
        expect(table.to_s).to eq \
          %q(+--------------+--------------+--------------+
             |       N      |    Doubled   |   Armadillo  |
             +--------------+--------------+--------------+
             |            1 |            2 |     false    |
             |            2 |            4 |     true     |
             |            3 |            6 |     false    |
             |            4 |            8 |     true     |
             |            5 |           10 |     false    |).gsub(/^ +/, "")
      end
    end

    describe "column alignment" do
      let(:column_width) { 8 }

      it "by default, aligns text left, booleans center and numbers right, with header text centered" do
        table.add_column(:to_s)
        table.add_column(:even?)
        table.add_column(:to_f)

        expect(table.to_s).to eq \
          %q(+----------+----------+----------+----------+----------+
             |     N    |  Doubled |   to_s   |   even?  |   to_f   |
             +----------+----------+----------+----------+----------+
             |        1 |        2 | 1        |   false  |      1.0 |
             |        2 |        4 | 2        |   true   |      2.0 |
             |        3 |        6 | 3        |   false  |      3.0 |
             |        4 |        8 | 4        |   true   |      4.0 |
             |        5 |       10 | 5        |   false  |      5.0 |).gsub(/^ +/, "")
      end

      context "when passed `align_header` and `align_body` are passed :left, :center or :right" do
        it "aligns header and body accordingly, overriding the default alignments" do
          table.add_column(:to_s, align_header: :left, align_body: :center)
          table.add_column(:even?, align_header: :left, align_body: :right)
          table.add_column(:to_f, align_header: :right, align_body: :left)
          expect(table.to_s).to eq \
            %q(+----------+----------+----------+----------+----------+
               |     N    |  Doubled | to_s     | even?    |     to_f |
               +----------+----------+----------+----------+----------+
               |        1 |        2 |     1    |    false | 1.0      |
               |        2 |        4 |     2    |     true | 2.0      |
               |        3 |        6 |     3    |    false | 3.0      |
               |        4 |        8 |     4    |     true | 4.0      |
               |        5 |       10 |     5    |    false | 5.0      |).gsub(/^ +/, "")
        end
      end
    end

    describe "`width` param" do
      it "fixes the column width at the passed value (not including padding), overriding the default "\
        "column width for the table" do
        table.add_column("Trebled", width: 16) { |n| n * 3 }
        expect(table.to_s).to eq \
          %q(+--------------+--------------+------------------+
             |       N      |    Doubled   |      Trebled     |
             +--------------+--------------+------------------+
             |            1 |            2 |                3 |
             |            2 |            4 |                6 |
             |            3 |            6 |                9 |
             |            4 |            8 |               12 |
             |            5 |           10 |               15 |).gsub(/^ +/, "")
      end
    end

    describe "`formatter` param" do
      it "formats the cell value for display, without changing the underlying cell value or its "\
        "default alignment" do
        table.add_column("Trebled", formatter: -> (val) { "%.2f" % val }) do |n|
          n * 3
        end
        expect(table.to_s).to eq \
          %q(+--------------+--------------+--------------+
             |       N      |    Doubled   |    Trebled   |
             +--------------+--------------+--------------+
             |            1 |            2 |         3.00 |
             |            2 |            4 |         6.00 |
             |            3 |            6 |         9.00 |
             |            4 |            8 |        12.00 |
             |            5 |           10 |        15.00 |).gsub(/^ +/, "")
        top_right_body_cell = table.first.to_a.last
        expect(top_right_body_cell).to eq(3)
        expect(top_right_body_cell).to be_a(Integer)
      end
    end

    describe "`styler` param" do
      it "styles the cell value by calling the styler on the underlying cell value and the formatted value, "\
        "without changing the underlying cell value's default alignment, and without affecting column width "\
        "calculations" do
        table.add_column(
          "Trebled",
          formatter: -> (val) { "%.2f" % val },
          styler: -> (val, str) { val == 6 ? "\033[31;1;4m#{str}\033[0m" : str }
        ) do |n|
          n * 3
        end

        expect(table.to_s).to eq \
          %Q(+--------------+--------------+--------------+
             |       N      |    Doubled   |    Trebled   |
             +--------------+--------------+--------------+
             |            1 |            2 |         3.00 |
             |            2 |            4 |         \033[31;1;4m6.00\033[0m |
             |            3 |            6 |         9.00 |
             |            4 |            8 |        12.00 |
             |            5 |           10 |        15.00 |).gsub(/^ +/, "")
        top_right_body_cell = table.first.to_a.last
        expect(top_right_body_cell).to eq(3)
        expect(top_right_body_cell).to be_a(Integer)
      end

      it "applies styling separately to each part of the wrapped cell content that's on its own line" do
        table = Tabulo::Table.new(%w[hello yes])
        table.add_column(:itself, width: 3, styler: -> (val, str) { "\033[31m#{str}\033[0m" })

        expect(table.to_s).to eq \
          %Q(+-----+
             | its |
             | elf |
             +-----+
             | \033[31mhel\033[0m |
             | \033[31mlo\033[0m  |
             | \033[31myes\033[0m |).gsub(/^ +/, "")
      end
    end

    describe "`header_styler` param" do
      it "styles the header cell content by calling the header_styler on the header text without "\
        "affecting width calculations" do
        table.add_column(
          "Trebled",
          formatter: -> (val) { "%.2f" % val },
          header_styler: -> (str) { "\033[31;1;4m#{str}\033[0m" }
        ) do |n|
          n * 3
        end

        expect(table.to_s).to eq \
          %Q(+--------------+--------------+--------------+
             |       N      |    Doubled   |    \033[31;1;4mTrebled\033[0m   |
             +--------------+--------------+--------------+
             |            1 |            2 |         3.00 |
             |            2 |            4 |         6.00 |
             |            3 |            6 |         9.00 |
             |            4 |            8 |        12.00 |
             |            5 |           10 |        15.00 |).gsub(/^ +/, "")
        top_right_body_cell = table.first.to_a.last
        expect(top_right_body_cell).to eq(3)
        expect(top_right_body_cell).to be_a(Integer)
      end

#       it "applies styling separately to each part of the wrapped cell content that's on its own line" do
#         table = Tabulo::Table.new(%w[hello yes])
#         table.add_column(:itself, width: 3, styler: -> (val, str) { "\033[31m#{str}\033[0m" })

#         expect(table.to_s).to eq \
#           %Q(+-----+
#              | its |
#              | elf |
#              +-----+
#              | \033[31mhel\033[0m |
#              | \033[31mlo\033[0m  |
#              | \033[31myes\033[0m |).gsub(/^ +/, "")
#       end
    end

    describe "`extractor` param" do
      context "when provided" do
        let(:table) do
          Tabulo::Table.new(1..5) do |t|
            t.add_column("N") { |s| s }
            t.add_column("x 2") do |n|
              n * 2
            end
            t.add_column("x 3", &(proc { |n| n * 3 }))
            t.add_column("x 4", &(-> (n) { n * 4 }))
            t.add_column("x 5") { |n| n * 5 }
          end
        end

        it "accepts a block or other callable, with which it calculates the cell value" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+--------------+--------------+--------------+
               |       N      |      x 2     |      x 3     |      x 4     |      x 5     |
               +--------------+--------------+--------------+--------------+--------------+
               |            1 |            2 |            3 |            4 |            5 |
               |            2 |            4 |            6 |            8 |           10 |
               |            3 |            6 |            9 |           12 |           15 |
               |            4 |            8 |           12 |           16 |           20 |
               |            5 |           10 |           15 |           20 |           25 |).gsub(/^ +/, "")
        end
      end

      context "when not provided" do
        let(:table) do
          Tabulo::Table.new(1..5) do |t|
            t.add_column(:even?)
          end
        end

        specify "the first argument is called as a method on each source item to derive the cell value" do
          expect(table.to_s).to eq \
            %q(+--------------+
               |     even?    |
               +--------------+
               |     false    |
               |     true     |
               |     false    |
               |     true     |
               |     false    |).gsub(/^ +/, "")
        end
      end
    end

    context "when the column label is not unique (even if one was passed a String and the other a Symbol)" do
      it "raises Tabulo::InvalidColumnLabelError" do
        table.add_column("abc") { |n| n * 3 }
        expect { table.add_column(:abc) { |n| n * 4 } }.to raise_error(Tabulo::InvalidColumnLabelError)
      end
    end

    context "when column label differs from that of an existing column only in regards to case" do
      it "does not raise an exception" do
        table.add_column("abc") { |n| n * 3 }
        expect { table.add_column("Abc") { |n| n * 4 } }.not_to raise_error
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

  describe "#formatted_header" do
    it "returns a string representing a header row for the table" do
      expect(table.formatted_header).to eq("|       N      |    Doubled   |")
    end
  end

  describe "#horizontal_rule" do
    it "returns a horizontal line made up of the horizontal rule character, and appropriately placed "\
      "corner characters, of an appropriate width for the table" do
      expect(table.horizontal_rule).to eq("+--------------+--------------+")
    end
  end

  describe "#pack" do
    let(:column_width) { 8 }

    before(:each) do
      table.add_column(:to_s)
      table.add_column("Is it\neven?") { |n| n.even? }
      table.add_column("dec", formatter: -> (n) { "%.#{n}f" % n }) { |n| n }
      table.add_column("word\nyep", width: 5) { |n| "w" * n * 2 }
      table.add_column("cool") { |n| "two\nlines" if n == 3 }
    end

    it "returns the Table itself" do
      expect(table.pack(max_table_width: [nil, 64, 47].sample)).to eq(table)
    end

    it "does not issue a deprecation warning" do
      expect(Tabulo::Deprecation).not_to receive(:warn)

      table.pack
    end

    context "when `max_table_width` is nil" do
      it "expands or contracts the column widths of the table as necessary so that they just "\
        "accommodate their header and formatted body contents without wrapping (assuming "\
        "source data is constant), except insofar as is required to honour newlines within "\
        "the cell content", :aggregate_failures do

        # Check that it adjusts column widths by shrinking
        expect { table.pack }.to change(table, :to_s).from(
          %q(+----------+----------+----------+----------+----------+-------+----------+
             |     N    |  Doubled |   to_s   |   Is it  |    dec   |  word |   cool   |
             |          |          |          |   even?  |          |  yep  |          |
             +----------+----------+----------+----------+----------+-------+----------+
             |        1 |        2 | 1        |   false  |      1.0 | ww    |          |
             |        2 |        4 | 2        |   true   |     2.00 | wwww  |          |
             |        3 |        6 | 3        |   false  |    3.000 | wwwww | two      |
             |          |          |          |          |          | w     | lines    |
             |        4 |        8 | 4        |   true   |   4.0000 | wwwww |          |
             |          |          |          |          |          | www   |          |
             |        5 |       10 | 5        |   false  |  5.00000 | wwwww |          |
             |          |          |          |          |          | wwwww |          |).gsub(/^ +/, "")

        ).to(
          %q(+---+---------+------+-------+---------+------------+-------+
             | N | Doubled | to_s | Is it |   dec   |    word    |  cool |
             |   |         |      | even? |         |     yep    |       |
             +---+---------+------+-------+---------+------------+-------+
             | 1 |       2 | 1    | false |     1.0 | ww         |       |
             | 2 |       4 | 2    |  true |    2.00 | wwww       |       |
             | 3 |       6 | 3    | false |   3.000 | wwwwww     | two   |
             |   |         |      |       |         |            | lines |
             | 4 |       8 | 4    |  true |  4.0000 | wwwwwwww   |       |
             | 5 |      10 | 5    | false | 5.00000 | wwwwwwwwww |       |).gsub(/^ +/, "")
        )

        # Let's do a quick check to make sure that it will also expand the total table width if required.
        small_table = Tabulo::Table.new(%w(hello goodbye), column_width: 3) do |t|
          t.add_column(:itself) { |s| s }
        end
        expect { small_table.pack }.to change(small_table, :to_s).from(
          %q(+-----+
             | its |
             | elf |
             +-----+
             | hel |
             | lo  |
             | goo |
             | dby |
             | e   |).gsub(/^ +/, "")
        ).to(
          %q(+---------+
             |  itself |
             +---------+
             | hello   |
             | goodbye |).gsub(/^ +/, "")
        )
      end
    end

    context "when `max_table_width` is nil" do
      context "when column_padding is > 1" do
        let(:column_padding) { 2 }

        it "expands or contracts the column widths of the table as necessary so that they just "\
          "accommodate their header and formatted body contents without wrapping (assuming "\
          "source data is constant), inclusive of additional padding, except insofar as is "\
          "required to honour newlines within the cell content" do

          # Check that it adjusts column widths by shrinking
          expect { table.pack }.to change(table, :to_s).to(
            %q(+-----+-----------+--------+---------+-----------+--------------+---------+
               |  N  |  Doubled  |  to_s  |  Is it  |    dec    |     word     |   cool  |
               |     |           |        |  even?  |           |      yep     |         |
               +-----+-----------+--------+---------+-----------+--------------+---------+
               |  1  |        2  |  1     |  false  |      1.0  |  ww          |         |
               |  2  |        4  |  2     |   true  |     2.00  |  wwww        |         |
               |  3  |        6  |  3     |  false  |    3.000  |  wwwwww      |  two    |
               |     |           |        |         |           |              |  lines  |
               |  4  |        8  |  4     |   true  |   4.0000  |  wwwwwwww    |         |
               |  5  |       10  |  5     |  false  |  5.00000  |  wwwwwwwwww  |         |).gsub(/^ +/, "")
          )
        end
      end
    end

    context "when `max_table_width` is passed an integer (assuming source data is constant)" do
      context "when `max_table_width` is wider than the existing table width" do
        it "amends the column widths of the table so that they just accommodate their header and "\
          "formatted body contents without wrapping (assuming source data is constant), except "\
          "insofar as is required to honour newlines within the cell content " do

          expect { table.pack(max_table_width: 64) }.to change(table, :to_s).from(
            %q(+----------+----------+----------+----------+----------+-------+----------+
               |     N    |  Doubled |   to_s   |   Is it  |    dec   |  word |   cool   |
               |          |          |          |   even?  |          |  yep  |          |
               +----------+----------+----------+----------+----------+-------+----------+
               |        1 |        2 | 1        |   false  |      1.0 | ww    |          |
               |        2 |        4 | 2        |   true   |     2.00 | wwww  |          |
               |        3 |        6 | 3        |   false  |    3.000 | wwwww | two      |
               |          |          |          |          |          | w     | lines    |
               |        4 |        8 | 4        |   true   |   4.0000 | wwwww |          |
               |          |          |          |          |          | www   |          |
               |        5 |       10 | 5        |   false  |  5.00000 | wwwww |          |
               |          |          |          |          |          | wwwww |          |).gsub(/^ +/, "")

          ).to(
            %q(+---+---------+------+-------+---------+------------+-------+
               | N | Doubled | to_s | Is it |   dec   |    word    |  cool |
               |   |         |      | even? |         |     yep    |       |
               +---+---------+------+-------+---------+------------+-------+
               | 1 |       2 | 1    | false |     1.0 | ww         |       |
               | 2 |       4 | 2    |  true |    2.00 | wwww       |       |
               | 3 |       6 | 3    | false |   3.000 | wwwwww     | two   |
               |   |         |      |       |         |            | lines |
               | 4 |       8 | 4    |  true |  4.0000 | wwwwwwww   |       |
               | 5 |      10 | 5    | false | 5.00000 | wwwwwwwwww |       |).gsub(/^ +/, "")

          )
        end
      end

      context "when `max_table_width` is too narrow to accommodate the packed columns" do
        it "amends the column widths of the table so that they just accommodate their header and "\
          "formatted body contents (assuming source data is constant) (except insofar as it required "\
          "to honour newlines within existing cell content), except that width is progressively "\
          "removed from the widest column until the table fits the passed width" do

          expect { table.pack(max_table_width: 55) }.to change(table, :to_s).from(
            %q(+----------+----------+----------+----------+----------+-------+----------+
               |     N    |  Doubled |   to_s   |   Is it  |    dec   |  word |   cool   |
               |          |          |          |   even?  |          |  yep  |          |
               +----------+----------+----------+----------+----------+-------+----------+
               |        1 |        2 | 1        |   false  |      1.0 | ww    |          |
               |        2 |        4 | 2        |   true   |     2.00 | wwww  |          |
               |        3 |        6 | 3        |   false  |    3.000 | wwwww | two      |
               |          |          |          |          |          | w     | lines    |
               |        4 |        8 | 4        |   true   |   4.0000 | wwwww |          |
               |          |          |          |          |          | www   |          |
               |        5 |       10 | 5        |   false  |  5.00000 | wwwww |          |
               |          |          |          |          |          | wwwww |          |).gsub(/^ +/, "")
          ).to(
            %q(+---+--------+------+-------+--------+--------+-------+
               | N | Double | to_s | Is it |   dec  |  word  |  cool |
               |   |    d   |      | even? |        |   yep  |       |
               +---+--------+------+-------+--------+--------+-------+
               | 1 |      2 | 1    | false |    1.0 | ww     |       |
               | 2 |      4 | 2    |  true |   2.00 | wwww   |       |
               | 3 |      6 | 3    | false |  3.000 | wwwwww | two   |
               |   |        |      |       |        |        | lines |
               | 4 |      8 | 4    |  true | 4.0000 | wwwwww |       |
               |   |        |      |       |        | ww     |       |
               | 5 |     10 | 5    | false | 5.0000 | wwwwww |       |
               |   |        |      |       |      0 | wwww   |       |).gsub(/^ +/, "")
          )
        end

        context "when column_padding is > 1" do
          let(:column_padding) { 2 }

          it "amends the column widths of the table so that they just accommodate their header and "\
            "formatted body contents (assuming source data is constant) (except insofar as it required "\
            "to honour newlines within existing cell content), including additional padding, except "\
            "that width is progressively removed from the widest column until the table fits the "\
            "passed width" do

            expect { table.pack(max_table_width: 69) }.to change(table, :to_s).from(
              %q(+------------+------------+------------+------------+------------+---------+------------+
                 |      N     |   Doubled  |    to_s    |    Is it   |     dec    |   word  |    cool    |
                 |            |            |            |    even?   |            |   yep   |            |
                 +------------+------------+------------+------------+------------+---------+------------+
                 |         1  |         2  |  1         |    false   |       1.0  |  ww     |            |
                 |         2  |         4  |  2         |    true    |      2.00  |  wwww   |            |
                 |         3  |         6  |  3         |    false   |     3.000  |  wwwww  |  two       |
                 |            |            |            |            |            |  w      |  lines     |
                 |         4  |         8  |  4         |    true    |    4.0000  |  wwwww  |            |
                 |            |            |            |            |            |  www    |            |
                 |         5  |        10  |  5         |    false   |   5.00000  |  wwwww  |            |
                 |            |            |            |            |            |  wwwww  |            |).gsub(/^ +/, "")
            ).to(
              %q(+-----+----------+--------+---------+----------+----------+---------+
                 |  N  |  Double  |  to_s  |  Is it  |    dec   |   word   |   cool  |
                 |     |     d    |        |  even?  |          |    yep   |         |
                 +-----+----------+--------+---------+----------+----------+---------+
                 |  1  |       2  |  1     |  false  |     1.0  |  ww      |         |
                 |  2  |       4  |  2     |   true  |    2.00  |  wwww    |         |
                 |  3  |       6  |  3     |  false  |   3.000  |  wwwwww  |  two    |
                 |     |          |        |         |          |          |  lines  |
                 |  4  |       8  |  4     |   true  |  4.0000  |  wwwwww  |         |
                 |     |          |        |         |          |  ww      |         |
                 |  5  |      10  |  5     |  false  |  5.0000  |  wwwwww  |         |
                 |     |          |        |         |       0  |  wwww    |         |).gsub(/^ +/, "")
            )
          end
        end

        context "when column_padding is 0" do
          let(:column_padding) { 0 }

          it "amends the column widths of the table so that they just accommodate their header and "\
            "formatted body contents (assuming source data is constant) (except insofar as it required "\
            "to honour newlines within existing cell content), with no padding, except "\
            "that width is progressively removed from the widest column until the table fits the "\
            "passed width" do

            expect { table.pack(max_table_width: 41) }.to change(table, :to_s).from(
              %q(+--------+--------+--------+--------+--------+-----+--------+
                 |    N   | Doubled|  to_s  |  Is it |   dec  | word|  cool  |
                 |        |        |        |  even? |        | yep |        |
                 +--------+--------+--------+--------+--------+-----+--------+
                 |       1|       2|1       |  false |     1.0|ww   |        |
                 |       2|       4|2       |  true  |    2.00|wwww |        |
                 |       3|       6|3       |  false |   3.000|wwwww|two     |
                 |        |        |        |        |        |w    |lines   |
                 |       4|       8|4       |  true  |  4.0000|wwwww|        |
                 |        |        |        |        |        |www  |        |
                 |       5|      10|5       |  false | 5.00000|wwwww|        |
                 |        |        |        |        |        |wwwww|        |).gsub(/^ +/, "")
            ).to(
              %q(+-+------+----+-----+------+------+-----+
                 |N|Double|to_s|Is it|  dec | word | cool|
                 | |   d  |    |even?|      |  yep |     |
                 +-+------+----+-----+------+------+-----+
                 |1|     2|1   |false|   1.0|ww    |     |
                 |2|     4|2   | true|  2.00|wwww  |     |
                 |3|     6|3   |false| 3.000|wwwwww|two  |
                 | |      |    |     |      |      |lines|
                 |4|     8|4   | true|4.0000|wwwwww|     |
                 | |      |    |     |      |ww    |     |
                 |5|    10|5   |false|5.0000|wwwwww|     |
                 | |      |    |     |     0|wwww  |     |).gsub(/^ +/, "")
            )
          end
        end
      end

      context "when `max_table_width` is very small" do
        it "only reduces column widths to the extent that there is at least a character's width "\
          "available in each column for content, plus one character of padding on either side" do
          table = Tabulo::Table.new(%w(hi there)) do |t|
            t.add_column(:itself) { |s| s }
            t.add_column(:length)
          end
          table.pack(max_table_width: 3)

          expect(table.to_s).to eq \
            %q(+---+---+
               | i | l |
               | t | e |
               | s | n |
               | e | g |
               | l | t |
               | f | h |
               +---+---+
               | h | 2 |
               | i |   |
               | t | 5 |
               | h |   |
               | e |   |
               | r |   |
               | e |   |).gsub(/^ +/, "")
        end
      end

      context "when `max_table_width` is passed :auto" do
        it "caps the table width at the screen width, as returned by TTY::Screen.width" do
          allow(TTY::Screen).to receive(:width).and_return(13)
          table = Tabulo::Table.new(1..3, :to_i, :to_f)
          table.pack(max_table_width: :auto)
          expect(table.to_s).to eq \
            %q(+-----+-----+
               | to_ | to_ |
               |  i  |  f  |
               +-----+-----+
               |   1 | 1.0 |
               |   2 | 2.0 |
               |   3 | 3.0 |).gsub(/^ +/, "")
        end
      end
    end
  end

  # FIXME Test various options
  describe "#transpose" do
    let(:source) { 1..3 }
    let(:intersection_character) { "*" }

    it "returns another table" do
      result = table.transpose
      expect(result).not_to be(table)
      expect(result).to be_a(Tabulo::Table)
    end

    it "returns a table that's transposed relative to the original one, with config options overridably "\
      "inherited from the original table, other than for the left-most column's width and alignment, which are "\
      "determined automatically, and default to left-aligned, respectively" do
      expect(table.transpose(column_width: 3).to_s).to eq \
        %q(*---------*-----*-----*-----*
           |         |  1  |  2  |  3  |
           *---------*-----*-----*-----*
           |       N |   1 |   2 |   3 |
           | Doubled |   2 |   4 |   6 |).gsub(/^ +/, "")
    end

    it "accepts options for determining the header, width and alignment of the left-most column of the "\
      "transposed table" do
      expect(table.transpose(column_width: 3, field_names_width: 20, field_names_header: "FIELDS",
        field_names_header_alignment: :center, field_names_body_alignment: :left).to_s).to eq \
        %q(*----------------------*-----*-----*-----*
           |        FIELDS        |  1  |  2  |  3  |
           *----------------------*-----*-----*-----*
           | N                    |   1 |   2 |   3 |
           | Doubled              |   2 |   4 |   6 |).gsub(/^ +/, "")
    end

    it "right-aligns the left-hand column of the new table by default" do
      expect(table.transpose(column_width: 3, field_names_width: 20, field_names_header: "FIELDS").to_s).to eq \
        %q(*----------------------*-----*-----*-----*
           |               FIELDS |  1  |  2  |  3  |
           *----------------------*-----*-----*-----*
           |                    N |   1 |   2 |   3 |
           |              Doubled |   2 |   4 |   6 |).gsub(/^ +/, "")
    end

    it "accepts a :headers option, allowing the caller to customize the column headers, "\
      "(other than the left-most column)" do
      expect(table.transpose(column_width: 3, headers: -> (n) { n * 2 }).to_s).to eq \
        %q(*---------*-----*-----*-----*
           |         |  2  |  4  |  6  |
           *---------*-----*-----*-----*
           |       N |   1 |   2 |   3 |
           | Doubled |   2 |   4 |   6 |).gsub(/^ +/, "")
    end
  end

  describe "#shrinkwrap" do
    let(:column_width) { 8 }

    before(:each) do
      table.add_column(:to_s)
      table.add_column("Is it\neven?") { |n| n.even? }
      table.add_column("dec", formatter: -> (n) { "%.#{n}f" % n }) { |n| n }
      table.add_column("word\nyep", width: 5) { |n| "w" * n * 2 }
      table.add_column("cool") { |n| "two\nlines" if n == 3 }
    end

    it "returns the Table itself" do
      expect(table.shrinkwrap!(max_table_width: [nil, 64, 47].sample)).to eq(table)
    end

    it "issues deprecation warning" do
      expect(Tabulo::Deprecation).to receive(:warn).with("`Tabulo::Table#shrinkwrap!'", "`#pack'")

      table.shrinkwrap!
    end

    context "when `max_table_width` is not provided" do
      it "expands or contracts the column widths of the table as necessary so that they just "\
        "accommodate their header and formatted body contents without wrapping (assuming "\
        "source data is constant), except insofar as is required to honour newlines within "\
        "the cell content", :aggregate_failures do

        # Check that it adjusts column widths by shrinking
        expect { table.shrinkwrap! }.to change(table, :to_s).from(
          %q(+----------+----------+----------+----------+----------+-------+----------+
             |     N    |  Doubled |   to_s   |   Is it  |    dec   |  word |   cool   |
             |          |          |          |   even?  |          |  yep  |          |
             +----------+----------+----------+----------+----------+-------+----------+
             |        1 |        2 | 1        |   false  |      1.0 | ww    |          |
             |        2 |        4 | 2        |   true   |     2.00 | wwww  |          |
             |        3 |        6 | 3        |   false  |    3.000 | wwwww | two      |
             |          |          |          |          |          | w     | lines    |
             |        4 |        8 | 4        |   true   |   4.0000 | wwwww |          |
             |          |          |          |          |          | www   |          |
             |        5 |       10 | 5        |   false  |  5.00000 | wwwww |          |
             |          |          |          |          |          | wwwww |          |).gsub(/^ +/, "")

        ).to(
          %q(+---+---------+------+-------+---------+------------+-------+
             | N | Doubled | to_s | Is it |   dec   |    word    |  cool |
             |   |         |      | even? |         |     yep    |       |
             +---+---------+------+-------+---------+------------+-------+
             | 1 |       2 | 1    | false |     1.0 | ww         |       |
             | 2 |       4 | 2    |  true |    2.00 | wwww       |       |
             | 3 |       6 | 3    | false |   3.000 | wwwwww     | two   |
             |   |         |      |       |         |            | lines |
             | 4 |       8 | 4    |  true |  4.0000 | wwwwwwww   |       |
             | 5 |      10 | 5    | false | 5.00000 | wwwwwwwwww |       |).gsub(/^ +/, "")
        )

        # Let's do a quick check to make sure that it will also expand the total table width if required.
        small_table = Tabulo::Table.new(%w(hello goodbye), column_width: 3) do |t|
          t.add_column(:itself) { |s| s }
        end
        expect { small_table.shrinkwrap! }.to change(small_table, :to_s).from(
          %q(+-----+
             | its |
             | elf |
             +-----+
             | hel |
             | lo  |
             | goo |
             | dby |
             | e   |).gsub(/^ +/, "")
        ).to(
          %q(+---------+
             |  itself |
             +---------+
             | hello   |
             | goodbye |).gsub(/^ +/, "")
        )
      end
    end

    context "when `max_table_width` is not provided" do
      context "when column_padding is > 1" do
        let(:column_padding) { 2 }

        it "expands or contracts the column widths of the table as necessary so that they just "\
          "accommodate their header and formatted body contents without wrapping (assuming "\
          "source data is constant), inclusive of additional padding, except insofar as is "\
          "required to honour newlines within the cell content" do

          # Check that it adjusts column widths by shrinking
          expect { table.shrinkwrap! }.to change(table, :to_s).to(
            %q(+-----+-----------+--------+---------+-----------+--------------+---------+
               |  N  |  Doubled  |  to_s  |  Is it  |    dec    |     word     |   cool  |
               |     |           |        |  even?  |           |      yep     |         |
               +-----+-----------+--------+---------+-----------+--------------+---------+
               |  1  |        2  |  1     |  false  |      1.0  |  ww          |         |
               |  2  |        4  |  2     |   true  |     2.00  |  wwww        |         |
               |  3  |        6  |  3     |  false  |    3.000  |  wwwwww      |  two    |
               |     |           |        |         |           |              |  lines  |
               |  4  |        8  |  4     |   true  |   4.0000  |  wwwwwwww    |         |
               |  5  |       10  |  5     |  false  |  5.00000  |  wwwwwwwwww  |         |).gsub(/^ +/, "")
          )
        end
      end
    end

    context "when `max_table_width` is provided (assuming source data is constant)" do
      context "when `max_table_width` is wider than the existing table width" do
        it "amends the column widths of the table so that they just accommodate their header and "\
          "formatted body contents without wrapping (assuming source data is constant), except "\
          "insofar as is required to honour newlines within the cell content " do

          expect { table.shrinkwrap!(max_table_width: 64) }.to change(table, :to_s).from(
            %q(+----------+----------+----------+----------+----------+-------+----------+
               |     N    |  Doubled |   to_s   |   Is it  |    dec   |  word |   cool   |
               |          |          |          |   even?  |          |  yep  |          |
               +----------+----------+----------+----------+----------+-------+----------+
               |        1 |        2 | 1        |   false  |      1.0 | ww    |          |
               |        2 |        4 | 2        |   true   |     2.00 | wwww  |          |
               |        3 |        6 | 3        |   false  |    3.000 | wwwww | two      |
               |          |          |          |          |          | w     | lines    |
               |        4 |        8 | 4        |   true   |   4.0000 | wwwww |          |
               |          |          |          |          |          | www   |          |
               |        5 |       10 | 5        |   false  |  5.00000 | wwwww |          |
               |          |          |          |          |          | wwwww |          |).gsub(/^ +/, "")

          ).to(
            %q(+---+---------+------+-------+---------+------------+-------+
               | N | Doubled | to_s | Is it |   dec   |    word    |  cool |
               |   |         |      | even? |         |     yep    |       |
               +---+---------+------+-------+---------+------------+-------+
               | 1 |       2 | 1    | false |     1.0 | ww         |       |
               | 2 |       4 | 2    |  true |    2.00 | wwww       |       |
               | 3 |       6 | 3    | false |   3.000 | wwwwww     | two   |
               |   |         |      |       |         |            | lines |
               | 4 |       8 | 4    |  true |  4.0000 | wwwwwwww   |       |
               | 5 |      10 | 5    | false | 5.00000 | wwwwwwwwww |       |).gsub(/^ +/, "")

          )
        end
      end

      context "when `max_table_width` is too narrow to accommodate the shrinkwrapped columns" do
        it "amends the column widths of the table so that they just accommodate their header and "\
          "formatted body contents (assuming source data is constant) (except insofar as it required "\
          "to honour newlines within existing cell content), except that width is progressively "\
          "removed from the widest column until the table fits the passed width" do

          expect { table.shrinkwrap!(max_table_width: 55) }.to change(table, :to_s).from(
            %q(+----------+----------+----------+----------+----------+-------+----------+
               |     N    |  Doubled |   to_s   |   Is it  |    dec   |  word |   cool   |
               |          |          |          |   even?  |          |  yep  |          |
               +----------+----------+----------+----------+----------+-------+----------+
               |        1 |        2 | 1        |   false  |      1.0 | ww    |          |
               |        2 |        4 | 2        |   true   |     2.00 | wwww  |          |
               |        3 |        6 | 3        |   false  |    3.000 | wwwww | two      |
               |          |          |          |          |          | w     | lines    |
               |        4 |        8 | 4        |   true   |   4.0000 | wwwww |          |
               |          |          |          |          |          | www   |          |
               |        5 |       10 | 5        |   false  |  5.00000 | wwwww |          |
               |          |          |          |          |          | wwwww |          |).gsub(/^ +/, "")
          ).to(
            %q(+---+--------+------+-------+--------+--------+-------+
               | N | Double | to_s | Is it |   dec  |  word  |  cool |
               |   |    d   |      | even? |        |   yep  |       |
               +---+--------+------+-------+--------+--------+-------+
               | 1 |      2 | 1    | false |    1.0 | ww     |       |
               | 2 |      4 | 2    |  true |   2.00 | wwww   |       |
               | 3 |      6 | 3    | false |  3.000 | wwwwww | two   |
               |   |        |      |       |        |        | lines |
               | 4 |      8 | 4    |  true | 4.0000 | wwwwww |       |
               |   |        |      |       |        | ww     |       |
               | 5 |     10 | 5    | false | 5.0000 | wwwwww |       |
               |   |        |      |       |      0 | wwww   |       |).gsub(/^ +/, "")
          )
        end

        context "when column_padding is > 1" do
          let(:column_padding) { 2 }

          it "amends the column widths of the table so that they just accommodate their header and "\
            "formatted body contents (assuming source data is constant) (except insofar as it required "\
            "to honour newlines within existing cell content), including additional padding, except "\
            "that width is progressively removed from the widest column until the table fits the "\
            "passed width" do

            expect { table.shrinkwrap!(max_table_width: 69) }.to change(table, :to_s).from(
              %q(+------------+------------+------------+------------+------------+---------+------------+
                 |      N     |   Doubled  |    to_s    |    Is it   |     dec    |   word  |    cool    |
                 |            |            |            |    even?   |            |   yep   |            |
                 +------------+------------+------------+------------+------------+---------+------------+
                 |         1  |         2  |  1         |    false   |       1.0  |  ww     |            |
                 |         2  |         4  |  2         |    true    |      2.00  |  wwww   |            |
                 |         3  |         6  |  3         |    false   |     3.000  |  wwwww  |  two       |
                 |            |            |            |            |            |  w      |  lines     |
                 |         4  |         8  |  4         |    true    |    4.0000  |  wwwww  |            |
                 |            |            |            |            |            |  www    |            |
                 |         5  |        10  |  5         |    false   |   5.00000  |  wwwww  |            |
                 |            |            |            |            |            |  wwwww  |            |).gsub(/^ +/, "")
            ).to(
              %q(+-----+----------+--------+---------+----------+----------+---------+
                 |  N  |  Double  |  to_s  |  Is it  |    dec   |   word   |   cool  |
                 |     |     d    |        |  even?  |          |    yep   |         |
                 +-----+----------+--------+---------+----------+----------+---------+
                 |  1  |       2  |  1     |  false  |     1.0  |  ww      |         |
                 |  2  |       4  |  2     |   true  |    2.00  |  wwww    |         |
                 |  3  |       6  |  3     |  false  |   3.000  |  wwwwww  |  two    |
                 |     |          |        |         |          |          |  lines  |
                 |  4  |       8  |  4     |   true  |  4.0000  |  wwwwww  |         |
                 |     |          |        |         |          |  ww      |         |
                 |  5  |      10  |  5     |  false  |  5.0000  |  wwwwww  |         |
                 |     |          |        |         |       0  |  wwww    |         |).gsub(/^ +/, "")
            )
          end
        end

        context "when column_padding is 0" do
          let(:column_padding) { 0 }

          it "amends the column widths of the table so that they just accommodate their header and "\
            "formatted body contents (assuming source data is constant) (except insofar as it required "\
            "to honour newlines within existing cell content), with no padding, except "\
            "that width is progressively removed from the widest column until the table fits the "\
            "passed width" do

            expect { table.shrinkwrap!(max_table_width: 41) }.to change(table, :to_s).from(
              %q(+--------+--------+--------+--------+--------+-----+--------+
                 |    N   | Doubled|  to_s  |  Is it |   dec  | word|  cool  |
                 |        |        |        |  even? |        | yep |        |
                 +--------+--------+--------+--------+--------+-----+--------+
                 |       1|       2|1       |  false |     1.0|ww   |        |
                 |       2|       4|2       |  true  |    2.00|wwww |        |
                 |       3|       6|3       |  false |   3.000|wwwww|two     |
                 |        |        |        |        |        |w    |lines   |
                 |       4|       8|4       |  true  |  4.0000|wwwww|        |
                 |        |        |        |        |        |www  |        |
                 |       5|      10|5       |  false | 5.00000|wwwww|        |
                 |        |        |        |        |        |wwwww|        |).gsub(/^ +/, "")
            ).to(
              %q(+-+------+----+-----+------+------+-----+
                 |N|Double|to_s|Is it|  dec | word | cool|
                 | |   d  |    |even?|      |  yep |     |
                 +-+------+----+-----+------+------+-----+
                 |1|     2|1   |false|   1.0|ww    |     |
                 |2|     4|2   | true|  2.00|wwww  |     |
                 |3|     6|3   |false| 3.000|wwwwww|two  |
                 | |      |    |     |      |      |lines|
                 |4|     8|4   | true|4.0000|wwwwww|     |
                 | |      |    |     |      |ww    |     |
                 |5|    10|5   |false|5.0000|wwwwww|     |
                 | |      |    |     |     0|wwww  |     |).gsub(/^ +/, "")
            )
          end
        end
      end

      context "when `max_table_width` is very small" do
        it "only reduces column widths to the extent that there is at least a character's width "\
          "available in each column for content, plus one character of padding on either side" do
          table = Tabulo::Table.new(%w(hi there)) do |t|
            t.add_column(:itself) { |s| s }
            t.add_column(:length)
          end
          table.shrinkwrap!(max_table_width: 3)

          expect(table.to_s).to eq \
            %q(+---+---+
               | i | l |
               | t | e |
               | s | n |
               | e | g |
               | l | t |
               | f | h |
               +---+---+
               | h | 2 |
               | i |   |
               | t | 5 |
               | h |   |
               | e |   |
               | r |   |
               | e |   |).gsub(/^ +/, "")
        end
      end

      context "when `max_table_width` is passed :auto" do
        it "caps the table width at the screen width, as returned by TTY::Screen.width" do
          allow(TTY::Screen).to receive(:width).and_return(13)
          table = Tabulo::Table.new(1..3, :to_i, :to_f)
          table.shrinkwrap!(max_table_width: :auto)
          expect(table.to_s).to eq \
            %q(+-----+-----+
               | to_ | to_ |
               |  i  |  f  |
               +-----+-----+
               |   1 | 1.0 |
               |   2 | 2.0 |
               |   3 | 3.0 |).gsub(/^ +/, "")
        end
      end
    end
  end

  describe "#formatted_body_row" do
    context "when passed `with_header: true`" do
      it "returns a string representing a row in the body of the table, with a header" do
        expect(table.formatted_body_row(3, with_header: true)).to eq \
          %q(+--------------+--------------+
             |       N      |    Doubled   |
             +--------------+--------------+
             |            3 |            6 |).gsub(/^ +/, "")
      end
    end

    context "when passed `with_header: false" do
      it "returns a string representing a row in the body of the table, without a header" do
        expect(table.formatted_body_row(3, with_header: false)).to eq("|            3 |            6 |")
      end
    end
  end
end
