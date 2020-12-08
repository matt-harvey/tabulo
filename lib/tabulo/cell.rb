require "unicode/display_width"

module Tabulo

  # Represents a single cell within the body of a {Table}.
  class Cell

    # @return the underlying value for this Cell
    attr_reader :value

    # @!visibility private
    def initialize(
      alignment:,
      cell_data:,
      formatter:,
      left_padding:,
      padding_character:,
      right_padding:,
      styler:,
      truncation_indicator:,
      value:,
      width:)

      @alignment = alignment
      @cell_data = cell_data
      @formatter = formatter
      @left_padding = left_padding
      @padding_character = padding_character
      @right_padding = right_padding
      @styler = styler
      @truncation_indicator = truncation_indicator
      @value = value
      @width = width
    end

    # @!visibility private
    def height
      subcells.size
    end

    # @!visibility private
    def padded_truncated_subcells(target_height)
      total_padding_amount = @left_padding + @right_padding
      truncated = (height > target_height)
      (0...target_height).map do |subcell_index|
        append_truncator = (truncated && (total_padding_amount != 0) && (subcell_index + 1 == target_height))
        padded_subcell(subcell_index, append_truncator)
      end
    end

    # @return [String] the content of the Cell, after applying the formatter for this Column (but
    #   without applying any wrapping or the styler).
    def formatted_content
      @formatted_content ||= apply_formatter
    end

    private

    def apply_formatter
      if @formatter.arity == 2
        @formatter.call(@value, @cell_data)
      else
        @formatter.call(@value)
      end
    end

    def apply_styler(content, line_index)
      case @styler.arity
      when 4
        @styler.call(@value, content, @cell_data, line_index)
      when 3
        @styler.call(@value, content, @cell_data)
      else
        @styler.call(@value, content)
      end
    end

    def subcells
      @subcells ||= calculate_subcells
    end

    def padded_subcell(subcell_index, append_truncator)
      lpad = @padding_character * @left_padding
      rpad =
        if append_truncator
          styled_truncation_indicator(subcell_index) + padding(@right_padding - 1)
        else
          padding(@right_padding)
        end
      inner = subcell_index < height ? subcells[subcell_index] : padding(@width)
      "#{lpad}#{inner}#{rpad}"
    end

    def padding(amount)
      @padding_character * amount
    end

    def styled_truncation_indicator(line_index)
      apply_styler(@truncation_indicator, line_index)
    end

    def calculate_subcells
      line_index = 0
      formatted_content.split(Util::NEWLINE, -1).flat_map do |substr|
        subsubcells, subsubcell, subsubcell_width = [], String.new(""), 0

        substr.scan(/\X/).each do |grapheme_cluster|
          grapheme_cluster_width = Unicode::DisplayWidth.of(grapheme_cluster)
          if subsubcell_width + grapheme_cluster_width > @width
            subsubcells << style_and_align_cell_content(subsubcell, line_index)
            subsubcell_width = 0
            subsubcell.clear
            line_index += 1
          end

          subsubcell << grapheme_cluster
          subsubcell_width += grapheme_cluster_width
        end

        subsubcells << style_and_align_cell_content(subsubcell, line_index)
        line_index += 1
        subsubcells
      end
    end

    def style_and_align_cell_content(content, line_index)
      padding = Util.max(@width - Unicode::DisplayWidth.of(content), 0)
      left_padding, right_padding =
        case real_alignment
        when :center
          half_padding = padding / 2
          [padding - half_padding, half_padding]
        when :left
          [0, padding]
        when :right
          [padding, 0]
        end

      "#{' ' * left_padding}#{apply_styler(content, line_index)}#{' ' * right_padding}"
    end

    def real_alignment
      return @alignment unless @alignment == :auto

      case @value
      when Numeric
        :right
      when TrueClass, FalseClass
        :center
      else
        :left
      end
    end
  end
end
