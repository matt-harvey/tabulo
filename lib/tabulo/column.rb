module Tabulo

  # @!visibility private
  class Column

    attr_accessor :width
    attr_reader :header
    attr_reader :index

    def initialize(
      align_body:,
      align_header:,
      extractor:,
      formatter:,
      header:,
      header_styler:,
      index:,
      padding_character:,
      styler:,
      truncation_indicator:,
      width:)

      @align_body = align_body
      @align_header = align_header
      @extractor = extractor
      @formatter = formatter
      @header = header
      @index = index

      @header_styler =
        if header_styler && (header_styler.arity == 2)
          -> (_, str, cell_data) { header_styler.call(str, cell_data.column_index) }
        elsif header_styler
          -> (_, str) { header_styler.call(str) }
        else
          -> (_, str) { str }
        end

      @padding_character = padding_character
      @styler = styler || -> (_, s) { s }
      @truncation_indicator = truncation_indicator
      @width = width
    end

    def header_cell
      if @header_styler.arity == 3
        cell_data = CellData.new(nil, nil, @index)
      end
      Cell.new(
        alignment: @align_header,
        cell_data: cell_data,
        formatter: -> (s) { s },
        padding_character: @padding_character,
        styler: @header_styler,
        truncation_indicator: @truncation_indicator,
        value: @header,
        width: @width,
      )
    end

    def body_cell(source, row_index:, column_index:)
      if body_cell_data_required?
        cell_data = CellData.new(source, row_index, @index)
      end
      Cell.new(
        alignment: @align_body,
        cell_data: cell_data,
        formatter: @formatter,
        padding_character: @padding_character,
        styler: @styler,
        truncation_indicator: @truncation_indicator,
        value: body_cell_value(source, row_index: row_index, column_index: column_index),
        width: @width,
      )
    end

    def body_cell_value(source, row_index:, column_index:)
      if @extractor.arity == 2
        @extractor.call(source, row_index)
      else
        @extractor.call(source)
      end
    end

    private

    def body_cell_data_required?
      @cell_data_required ||= (@styler.arity == 3 || @formatter.arity == 2)
    end
  end
end
