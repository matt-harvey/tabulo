require "spec_helper"

describe Tabulo::Border do

  around(:all) do |group|
    Tabulo::Deprecation.without_warnings { group.run }
  end

  describe "#initialize" do
    it "returns a new Border" do
      border = Tabulo::Border.new
      expect(border).to be_a(Tabulo::Border)
    end

    it "initializes various instance variables" do
      border = Tabulo::Border.new(corner_top_left: "/", tee_left: "~", intersection: "*")
      expect(border.instance_variable_get(:@corner_top_left)).to eq("/")
      expect(border.instance_variable_get(:@tee_left)).to eq("~")
      expect(border.instance_variable_get(:@intersection)).to eq("*")
    end
  end

  describe ".from" do
    subject do
      Tabulo::Border.from(initializer, styler)
    end

    let(:styler) { nil }

    context "when passed `:classic`" do
      let(:initializer) { :classic }

      it "returns a new Border" do
        expect(subject).to be_a(Tabulo::Border)
      end
    end

    context "when passed `:legacy`" do
      let(:initializer) { :legacy }

      it "returns a new Border" do
        expect(subject).to be_a(Tabulo::Border)
      end
    end

    context "when passed `:markdown`" do
      let(:initializer) { :markdown }

      it "returns a new Border" do
        expect(subject).to be_a(Tabulo::Border)
      end
    end

    context "when passed `:modern`" do
      let(:initializer) { :modern }

      it "returns a new Border" do
        expect(subject).to be_a(Tabulo::Border)
      end
    end

    context "when passed `:blank`" do
      let(:initializer) { :blank }

      it "returns a new Border" do
        expect(subject).to be_a(Tabulo::Border)
      end
    end

    context "when `initializer` parameter is passed an unrecognized value" do
      let(:initializer) { :coolness }

      it "raises an exception" do
        expect { subject }.to raise_error(Tabulo::InvalidBorderError)
      end
    end

    context "when passed a callable to the `styler` parameter" do
      let(:initializer) { :classic }
      let(:styler) { double("styler", call: "some styled border") }

      it "uses the styler to style the border characters" do
        expect(styler).to receive(:call)
        subject.join_cell_contents(%w[hello goodbye])
      end
    end
  end

  describe "#horizontal_rule" do
    it "returns a horizontal line suitable for rendering within a table with the indicated column widths, "\
      "at the indicated position, with" do
      border = Tabulo::Border.from(:modern)
      column_widths = [3, 5, 12]

      expect(border.horizontal_rule(column_widths, :top)).to eq("┌───┬─────┬────────────┐")
      expect(border.horizontal_rule(column_widths, :middle)).to eq("├───┼─────┼────────────┤")
      expect(border.horizontal_rule(column_widths, :bottom)).to eq("└───┴─────┴────────────┘")
    end
  end

  describe "#join_cell_contents" do
    it "renders a string in which the passed cell contents are joined by styled border characters" do
      border = Tabulo::Border.from(:classic, -> (x) { "!#{x}!" })
      expect(border.join_cell_contents([" hello ", " good morning ", " huh "])).to \
        eq("!|! hello !|! good morning !|! huh !|!")
    end
  end

end
