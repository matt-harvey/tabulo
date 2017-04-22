module Tabulo

  class Table
    include Enumerable

    DEFAULT_COLUMN_WIDTH = 8
    DEFAULT_HORIZONTAL_RULE_CHARACTER = "-"

    attr_reader :columns

    def initialize(sources, options = { })
      opts = {
        columns: [],
        header_frequency: :start,

        # nil to wrap to no max, 1 to wrap to 1 row then truncate, etc..
        wrap_header_cells_to: nil,
        wrap_body_cells_to: nil

      }.merge(options)

      @header_frequency = opts[:header_frequency]
      @wrap_header_cells_to = opts[:wrap_header_cells_to]
      @wrap_body_cells_to = opts[:wrap_body_cells_to]
      @sources = sources
      @joiner = "|"
      @corner_character = "+"
      @horizontal_rule_character = "-"
      @truncation_indicator = "~"
      @padding_character = " "
      @default_column_width = DEFAULT_COLUMN_WIDTH
      @columns = opts[:columns].map do |item|
        case item
        when Column
          item
        else
          Column.new({
            label: item.to_sym,
            header: item.to_s,
            align_header: :center,
            horizontal_rule_character: @horizontal_rule_character,
            width: @default_column_width,
            formatter: :to_s.to_proc
          })
        end
      end
      yield self if block_given?
    end

    def add_column(label, options = {}, &extractor)
      @columns << Column.new({
        label: label.to_sym,
        header: label.to_s,
        truncate: true,
        align_header: :center,
        horizontal_rule_character: @horizontal_rule_character,
        width: @default_column_width,
        extractor: extractor || (label.respond_to?(:to_proc) ? label.to_proc : proc { nil }),
        formatter: :to_s.to_proc

      }.merge(options))
    end

    def to_s
      join_lines(map(&:to_s))
    end

    def each
      @sources.each_with_index do |source, index|
        include_header =
          case @header_frequency
          when :start
            index == 0
          when Fixnum
            index % @header_frequency == 0
          else
            @header_frequency
          end
        yield body_row(source, with_header: include_header)
      end
    end

    def header_row
      format_row(true, &:header_cell)
    end

    def horizontal_rule
      format_row(false, @horizontal_rule_character, @corner_character, &:horizontal_rule)
    end

    def formatted_body_row(source, options = { with_header: false })
      inner = format_row { |column| column.body_cell(source) }
      if options[:with_header]
        join_lines([horizontal_rule, header_row, horizontal_rule, inner])
      else
        inner
      end
    end

    private

    def body_row(source, options = { with_header: false })
      Row.new(self, source, options)
    end

    def format_row(header = false, padder = @padding_character, joiner = @joiner)
      cell_stacks = @columns.map do |column|
        raw = yield column
        wrap = (header ? @wrap_header_cells_to : @wrap_body_cells_to)
        column_width = column.width
        cell_body_length = (wrap ? column_width * wrap : raw.length)
        truncated = (cell_body_length < raw.length)
        cell_body = raw[0...cell_body_length]
        num_subcells = (cell_body_length.to_f / column_width).ceil
        (0...num_subcells).map do |i|
          s = cell_body.slice(i * column_width, column_width)
          right_padder = ((truncated && i == num_subcells - 1) ? @truncation_indicator : padder)
          "#{padder}#{s}#{padder * (column_width - s.length)}#{right_padder}"
        end
      end

      subrows = (0...cell_stacks.map(&:size).max).map do |subrow_index|
        cell_stacks.map.with_index do |cell_stack, column_index|
          if subrow_index < cell_stack.size
            cell_stack[subrow_index]
          else
            "#{padder}#{' ' * @columns[column_index].width}#{padder}"
          end
        end
      end

      join_lines(subrows.map { |subrow| "#{joiner}#{subrow.join(joiner)}#{joiner}" })
    end

    def join_lines(lines)
      lines.join($/)  # join strings with cross-platform newline
    end
  end
end
