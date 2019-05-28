require "unicode/display_width"

module Tabulo

  # @!visibility private
  class Cell

    def initialize(value:, formatter:, alignment:, width:, styler:, truncation_indicator:, padding_character:)
      @value = value
      @formatter = formatter
      @alignment = alignment
      @width = width
      @styler = styler
      @truncation_indicator = truncation_indicator
      @padding_character = padding_character
    end

    def height
      subcells.size
    end

    def padded_truncated_subcells(target_height, padding_amount)
      truncated = (height > target_height)
      (0...target_height).map do |subcell_index|
        append_truncator = (truncated && (padding_amount != 0) && (subcell_index + 1 == target_height))
        padded_subcell(subcell_index, padding_amount, append_truncator)
      end
    end

    def formatted_content
      @formatted_content ||= @formatter.call(@value)
    end

    private

    def subcells
      @subcells ||= calculate_subcells
    end

    def padded_subcell(subcell_index, padding_amount, append_truncator)
      lpad = @padding_character * padding_amount
      rpad = append_truncator ? styled_truncation_indicator + padding(padding_amount - 1) : padding(padding_amount)
      inner = subcell_index < height ? subcells[subcell_index] : padding(@width)
      "#{lpad}#{inner}#{rpad}"
    end

    def padding(amount)
      @padding_character * amount
    end

    def styled_truncation_indicator
      @styler.call(@value, @truncation_indicator)
    end

    def calculate_subcells
      formatted_content.split($/, -1).flat_map do |substr|
        subsubcells, subsubcell, subsubcell_width = [], String.new(""), 0

        substr.scan(/\X/).each do |grapheme_cluster|
          grapheme_cluster_width = Unicode::DisplayWidth.of(grapheme_cluster)
          if subsubcell_width + grapheme_cluster_width > @width
            subsubcells << style_and_align_cell_content(subsubcell)
            subsubcell_width = 0
            subsubcell.clear
          end

          subsubcell << grapheme_cluster
          subsubcell_width += grapheme_cluster_width
        end

        subsubcells << style_and_align_cell_content(subsubcell)
      end
    end

    def style_and_align_cell_content(content)
      padding = [@width - Unicode::DisplayWidth.of(content), 0].max
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

      "#{' ' * left_padding}#{@styler.call(@value, content)}#{' ' * right_padding}"
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
