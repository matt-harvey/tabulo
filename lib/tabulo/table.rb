module Tabulo

  # Represents a table primarily intended for "pretty-printing" in a fixed-width font.
  #
  # A Table is also an Enumerable, of which each element is a Tabulo::Row.
  class Table
    include Enumerable

    DEFAULT_COLUMN_WIDTH = 8

    HORIZONTAL_RULE_CHARACTER = "-"
    CORNER_CHARACTER = "+"

    attr_reader :columns

    # Public: Initializes and returns a new Table.
    #
    # sources - the underlying Enumerable from which the table will derive its data
    #
    # options - a Hash of options providing for customization of the Table:
    #
    #           :columns  - An Array (default: []) specifying the initial columns (note more can be
    #                       added later using #add_column). Each element of the Array
    #                       should be either a Symbol or a Column. If it's a Symbol,
    #                       it will be used to initialize a Column whose content is
    #                       created by calling the corresponding method on each
    #                       element of sources.
    #
    #           :header_frequency - Controls the display of Column headers. Possible values:
    #
    #                               <tt>:start</tt> (default) - show column headers at top of table only
    #
    #                               <tt>nil</tt>              - do not show column headers.
    #
    #                               N (a Fixnum > 0)   - show column headers at start, then repeated
    #                                                    every N rows.
    #
    #           :wrap_header_cells_to - Controls wrapping behaviour for header cells if the content
    #                                   thereof is longer than the Column's fixed width. Possible
    #                                   values:
    #
    #                                   <tt>nil</tt>      - wrap content for as many rows as necessary
    #
    #                                   N (a Fixnum > 0) - wrap content for up to N rows and
    #                                                      truncate thereafter
    #
    #           :wrap_body_cells_to   - Controls wrapping behaviour for table cells (excluding
    #                                   headers). Possible values:
    #
    #                                   <tt>nil</tt>       - wrap content for as many rows as necessary
    #
    #                                   N (a `Fixnum` > 0) - wrap content for up to N rows and
    #                                                      truncate thereafter
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
      @truncation_indicator = "~"
      @padding_character = " "
      @default_column_width = DEFAULT_COLUMN_WIDTH
      @columns = opts[:columns].map { |item| make_column(item) }
      yield self if block_given?
    end

    def add_column(label, options = {}, &extractor)
      @columns << make_column(label, extractor: extractor)
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
      format_row(false, HORIZONTAL_RULE_CHARACTER, CORNER_CHARACTER, &:horizontal_rule)
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

    def make_column(item, options = { })
      case item
      when Column
        item
      else
        Column.new({
          label: item.to_sym,
          header: item.to_s,
          align_header: :center,
          width: @default_column_width,
          formatter: :to_s.to_proc

        }.merge(options))
      end
    end
  end
end
