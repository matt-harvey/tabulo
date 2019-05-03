require "unicode/display_width"

module Tabulo

  # @!visibility private
  class Column

    attr_accessor :width
    attr_reader :header

    def initialize(header:, width:, align_header:, align_body:, formatter:, extractor:)
      @header = header
      @width = width
      @align_header = align_header
      @align_body = align_body
      @formatter = formatter
      @extractor = extractor
    end

    def header_subcells
      infilled_subcells(@header, @align_header)
    end

    def body_subcells(source)
      cell_datum = body_cell_value(source)
      formatted_content = @formatter.call(cell_datum)
      real_alignment = (@align_body == :auto ? infer_alignment(cell_datum) : @align_body)
      infilled_subcells(formatted_content, real_alignment)
    end

    def formatted_cell_content(source)
      @formatter.call(body_cell_value(source))
    end

    def body_cell_value(source)
      @extractor.call(source)
    end

    private

    def infilled_subcells(str, real_alignment)
      str.split($/, -1).flat_map do |substr|
        substr_grapheme_clusters = substr.scan(/\X/)
        subsubcells = []
        current_subsubcell_grapheme_clusters = []
        current_subsubcell_display_width = 0
        substr_grapheme_clusters.each do |sgc|
          sgc_display_width = Unicode::DisplayWidth.of(sgc)
          if sgc_display_width + current_subsubcell_display_width > width
            subsubcells << current_subsubcell_grapheme_clusters.join("")
            current_subsubcell_grapheme_clusters.clear
            current_subsubcell_display_width = 0
          end

          current_subsubcell_grapheme_clusters << sgc
          current_subsubcell_display_width += sgc_display_width
        end
        subsubcells << current_subsubcell_grapheme_clusters.join("")
        subsubcells.map { |s| align_cell_content(s, real_alignment) }
      end
    end

    def align_cell_content(content, real_alignment)
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

      "#{' ' * left_padding}#{content}#{' ' * right_padding}"
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
