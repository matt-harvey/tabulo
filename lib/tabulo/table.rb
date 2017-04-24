module Tabulo

  # Represents a table primarily intended for "pretty-printing" in a fixed-width font.
  #
  # A Table is also an Enumerable, of which each element is a {Row}.
  class Table
    include Enumerable

    DEFAULT_COLUMN_WIDTH = 8

    HORIZONTAL_RULE_CHARACTER = "-"
    CORNER_CHARACTER = "+"

    # @!visibility private
    attr_reader :columns

    # @param [Enumerable] sources the underlying Enumerable from which the table will derive its data
    # @param [Hash] options
    # @option options [Array[Symbol]] :columns ([]) Specifies the initial columns.
    #   Each element of the Array  will be used to create a column whose content is
    #   created by calling the corresponding method on each element of sources. Note
    #   the {#add_column} method is a much more flexible way to set up columns on the table.
    # @option options [:start, nil, Fixnum] :header_frequency (:start) Controls the display of column headers.
    #   If passed <tt>:start</tt>, headers will be shown at the top of the table only. If passed <tt>nil</tt>,
    #   headers will not be shown. If passed a Fixnum N (> 0), headers will be shown at the top of the table,
    #   then repeated every N rows.
    # @option options [nil, Fixnum] :wrap_header_cells_to (nil) Controls wrapping behaviour for header
    #   cells if the content thereof is longer than the column's fixed width. If passed <tt>nil</tt> (default),
    #   content will be wrapped for as many rows as required to accommodate it. If passed a Fixnum N (> 0),
    #   content will be wrapped up to N rows and then truncated thereafter.
    # @option options [nil, Fixnum] :wrap_body_cells_to (nil) Controls wrapping behaviour for table cells (excluding
    #   headers), if their content is longer than the column's fixed width. If passed <tt>nil</tt>, content will
    #   be wrapped for as many rows as required to accommodate it. If passed a Fixnum N (> 0), content will be
    #   wrapped up to N rows and then truncated thereafter.
    #
    # @return [Table] a new Table
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

    # Adds a column to the Table.
    #
    # @param [Symbol, String] label A unique identifier for this column, which by default will
    #   also be used as the column header text (see also the header option). If the
    #   extractor argument is not also provided, then the label argument should correspond to
    #   a method to be called on each item in the table sources to provide the content
    #   for this column.
    #
    # @param [Hash] options
    # @option options [String] :header Text to be displayed in the column header. By default the column
    #   label will also be used as its header text.
    # @option options [:left, :center, :right] :align_header (:center) Specifies how the header text
    #   should be aligned.
    # @option options [:left, :center, :right, nil] :align_body (nil) Specifies how the cell body contents
    #   should be aligned. Possible If <tt>nil</tt> is passed, then the alignment is determined
    #   by the type of the cell value, with numbers aligned right, booleans center-aligned, and
    #   other values left-aligned. Note header text alignment is configured separately using the
    #   :align_header option.
    # @option options [Fixnum] :width (8) Specifies the width of the
    #   column, excluding padding.
    # @option options [#to_proc] :formatter (:to_s.to_proc) A lambda or other callable object that
    #   will be passed the calculated value of each cell to determine how it should be displayed. This
    #   is distinct from the extractor (see below). For example, if the extractor for this column
    #   generates a Date, then the formatter might format that Date in a particular way.
    #   If no formatter is provided, then <tt>.to_s</tt> will be called on
    #   the extracted value of each cell to determine its displayed content.
    # @param [#to_proc] extractor A block or other callable
    #   that will be passed each of the Table sources to determine the value in each cell of this
    #   column. If this is not provided, then the column label will be treated as a method to be
    #   called on each source item to determine each cell's value.
    #
    def add_column(label, options = { }, &extractor)
      @columns << make_column(label, extractor: extractor)
    end

    # @return [String] a graphical "ASCII" representation of the Table, suitable for
    #   display in a fixed-width font.
    def to_s
      join_lines(map(&:to_s))
    end

    # Calls the given block once for each {Row} in the Table, passing that {Row} as parameter.
    #
    # @example
    #   table.each do |row|
    #     puts row
    #   end
    #
    # Note that when printed, the first row will visually include the headers (assuming these
    # were not disabled when the Table was initialized).
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

    # @return [String] an "ASCII" graphical representation of the Table column headers.
    def formatted_header
      format_row(true, &:header_cell)
    end

    # @return [String] an "ASCII" graphical representation of a horizontal
    #   dividing line suitable for printing at any point in the table.
    #
    # @example Print a horizontal divider after every row:
    #   table.each do |row|
    #     puts row
    #     puts table.horizontal_rule
    #   end
    #
    def horizontal_rule
      format_row(false, HORIZONTAL_RULE_CHARACTER, CORNER_CHARACTER, &:horizontal_rule)
    end

    # @!visibility private
    def formatted_body_row(source, options = { with_header: false })
      inner = format_row { |column| column.body_cell(source) }
      if options[:with_header]
        join_lines([horizontal_rule, formatted_header, horizontal_rule, inner])
      else
        inner
      end
    end

    private

    # @!visibility private
    def body_row(source, options = { with_header: false })
      Row.new(self, source, options)
    end

    # @!visibility private
    def format_row(header = false, padder = @padding_character, joiner = @joiner)
      # TODO Tidy this up -- or at least comment it.
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

    # @!visibility private
    def join_lines(lines)
      lines.join($/)  # join strings with cross-platform newline
    end

    # @!visibility private
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
