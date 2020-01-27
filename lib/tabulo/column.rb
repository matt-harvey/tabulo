module Tabulo

  # @!visibility private
  class Column

    attr_accessor :width
    attr_reader :header

    def initialize(
      align_body:,
      align_header:,
      extractor:,
      formatter:,
      header:,
      header_styler:,
      padding_character:,
      styler:,
      truncation_indicator:,
      width:)

      @align_body = align_body
      @align_header = align_header
      @extractor = extractor
      @formatter = formatter
      @header = header

      @header_styler =
        if header_styler
          -> (_, s) { header_styler.call(s) }
        else
          -> (_, s) { s }
        end

      @padding_character = padding_character
      @styler = styler || -> (_, s) { s }
      @truncation_indicator = truncation_indicator
      @width = width
    end

    def header_cell
      Cell.new(
        alignment: @align_header,
        formatter: -> (s) { s },
        padding_character: @padding_character,
        styler: @header_styler,
        truncation_indicator: @truncation_indicator,
        value: @header,
        width: @width,
      )
    end

    def body_cell(source)
      Cell.new(
        alignment: @align_body,
        formatter: @formatter,
        padding_character: @padding_character,
        styler: @styler,
        truncation_indicator: @truncation_indicator,
        value: body_cell_value(source),
        width: @width,
      )
    end

    def body_cell_value(source)
      @extractor.call(source)
    end
  end
end
