module Tabulo

  # @!visibility private
  class Column

    attr_accessor :width
    attr_reader :header
    attr_reader :index
    attr_reader :left_padding
    attr_reader :right_padding

    def initialize(
      align_body:,
      align_header:,
      extractor:,
      formatter:,
      header:,
      header_styler:,
      index:,
      left_padding:,
      padding_character:,
      right_padding:,
      styler:,
      truncation_indicator:,
      wrap_preserve:,
      width:)

      @align_body = align_body
      @align_header = align_header
      @extractor = extractor
      @formatter = formatter
      @header = header
      @index = index
      @left_padding = left_padding
      @right_padding = right_padding

      @header_styler =
        if header_styler
          case header_styler.arity
          when 3
            -> (_, str, cell_data, line_index) { header_styler.call(str, cell_data.column_index, line_index) }
          when 2
            -> (_, str, cell_data) { header_styler.call(str, cell_data.column_index) }
          else
            -> (_, str) { header_styler.call(str) }
          end
        else
          -> (_, str) { str }
        end

      @padding_character = padding_character
      @styler = styler || -> (_, s) { s }
      @truncation_indicator = truncation_indicator
      @wrap_preserve = wrap_preserve
      @width = width
    end

    def header_cell
      if @header_styler.arity >= 3
        cell_data = CellData.new(nil, nil, @index)
      end
      Cell.new(
        alignment: @align_header,
        cell_data: cell_data,
        formatter: -> (s) { s },
        left_padding: @left_padding,
        padding_character: @padding_character,
        right_padding: @right_padding,
        styler: @header_styler,
        truncation_indicator: @truncation_indicator,
        value: @header,
        wrap_preserve: @wrap_preserve,
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
        left_padding: @left_padding,
        padding_character: @padding_character,
        right_padding: @right_padding,
        styler: @styler,
        truncation_indicator: @truncation_indicator,
        value: body_cell_value(source, row_index: row_index, column_index: column_index),
        wrap_preserve: @wrap_preserve,
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

    def padded_width
      width + total_padding
    end

    def total_padding
      @left_padding + @right_padding
    end

    private

    def body_cell_data_required?
      @cell_data_required ||= (@styler.arity == 3 || @formatter.arity == 2)
    end
  end
end
