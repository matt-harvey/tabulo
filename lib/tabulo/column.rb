require "unicode/display_width"

module Tabulo

  # @!visibility private
  class Column

    attr_accessor :width
    attr_reader :header

    def initialize(header:, width:, align_header:, align_body:, formatter:, extractor:, styler:, header_styler:)
      @header = header
      @width = width
      @align_header = align_header
      @align_body = align_body
      @formatter = formatter
      @extractor = extractor
      @styler = styler
      @header_styler = header_styler
    end

    def header_subcells
      infilled_subcells(
        @header,
        @header,
        @align_header,
        @header_styler ? -> (_, s) { @header_styler.call(s) } : nil
      )
    end

    def body_subcells(source)
      cell_datum = body_cell_value(source)
      formatted_content = @formatter.call(cell_datum)
      real_alignment = (@align_body == :auto ? infer_alignment(cell_datum) : @align_body)
      infilled_subcells(cell_datum, formatted_content, real_alignment, @styler)
    end

    def formatted_cell_content(source)
      @formatter.call(body_cell_value(source))
    end

    def body_cell_value(source)
      @extractor.call(source)
    end

    private

    def infilled_subcells(cell_datum, str, real_alignment, styler)
      str.split($/, -1).flat_map do |substr|
        subsubcells, subsubcell, subsubcell_width = [], String.new(""), 0

        substr.scan(/\X/).each do |grapheme_cluster|
          grapheme_cluster_width = Unicode::DisplayWidth.of(grapheme_cluster)
          if subsubcell_width + grapheme_cluster_width > width
            subsubcells << style_and_align_cell_content(subsubcell, cell_datum, real_alignment, styler)
            subsubcell_width = 0
            subsubcell.clear
          end

          subsubcell << grapheme_cluster
          subsubcell_width += grapheme_cluster_width
        end

        subsubcells << style_and_align_cell_content(subsubcell, cell_datum, real_alignment, styler)
      end
    end

    def style_and_align_cell_content(content, cell_datum, real_alignment, styler)
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

      styled_content = (styler ? styler.call(cell_datum, content) : content)
      "#{' ' * left_padding}#{styled_content}#{' ' * right_padding}"
    end

    def infer_alignment(cell_datum)
      case cell_datum
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
