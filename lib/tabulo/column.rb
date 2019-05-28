module Tabulo

  # @!visibility private
  class Column

    attr_accessor :width
    attr_reader :header

    def initialize(header:, width:, align_header:, align_body:, formatter:, extractor:, styler:,
      header_styler:, truncation_indicator:, padding_character:)

      @header = header
      @width = width
      @align_header = align_header
      @align_body = align_body
      @formatter = formatter
      @extractor = extractor
      @styler = styler || -> (_, s) { s }

      @header_styler =
        if header_styler
          -> (_, s) { header_styler.call(s) }
        else
          -> (_, s) { s }
        end

      @truncation_indicator = truncation_indicator
      @padding_character = padding_character
    end

    def header_cell
      Cell.new(
        value: @header,
        formatter: -> (s) { s },
        alignment: @align_header,
        width: @width,
        styler: @header_styler,
        truncation_indicator: @truncation_indicator,
        padding_character: @padding_character,
      )
    end

    def body_cell(source)
      Cell.new(
        value: body_cell_value(source),
        formatter: @formatter,
        alignment: @align_body,
        width: @width,
        styler: @styler,
        truncation_indicator: @truncation_indicator,
        padding_character: @padding_character,
      )
    end

    def body_cell_value(source)
      @extractor.call(source)
    end
  end
end
