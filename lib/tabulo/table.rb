module Tabulo

  # Represents a table primarily intended for "pretty-printing" in a fixed-width font.
  #
  # A Table is also an Enumerable, of which each element is a {Row}.
  class Table
    include Enumerable

    DEFAULT_COLUMN_WIDTH = 12
    HORIZONTAL_RULE_CHARACTER = "-"
    VERTICAL_RULE_CHARACTER = "|"
    CORNER_CHARACTER = "+"
    PADDING_CHARACTER = " "
    TRUNCATION_INDICATOR = "~"

    # @!visibility private
    attr_reader :columns

    # @param [Enumerable] sources the underlying Enumerable from which the table will derive its data
    # @param [Array[Symbol]] columns Specifies the initial columns.
    #   Each element of the Array  will be used to create a column whose content is
    #   created by calling the corresponding method on each element of sources. Note
    #   the {#add_column} method is a much more flexible way to set up columns on the table.
    # @param [Fixnum, nil] column_width The default column width for columns in this
    #   table, not excluding padding. If nil, then DEFAULT_COLUMN_WIDTH will be used.
    # @param [:start, nil, Fixnum] header_frequency Controls the display of column headers.
    #   If passed <tt>:start</tt>, headers will be shown at the top of the table only. If passed <tt>nil</tt>,
    #   headers will not be shown. If passed a Fixnum N (> 0), headers will be shown at the top of the table,
    #   then repeated every N rows.
    # @param [nil, Fixnum] wrap_header_cells_to Controls wrapping behaviour for header
    #   cells if the content thereof is longer than the column's fixed width. If passed <tt>nil</tt> (default),
    #   content will be wrapped for as many rows as required to accommodate it. If passed a Fixnum N (> 0),
    #   content will be wrapped up to N rows and then truncated thereafter.
    # @param [nil, Fixnum] wrap_body_cells_to Controls wrapping behaviour for table cells (excluding
    #   headers), if their content is longer than the column's fixed width. If passed <tt>nil</tt>, content will
    #   be wrapped for as many rows as required to accommodate it. If passed a Fixnum N (> 0), content will be
    #   wrapped up to N rows and then truncated thereafter.
    #
    # @return [Table] a new Table
    def initialize(sources, columns: [], column_width: nil, header_frequency: :start,
      wrap_header_cells_to: nil, wrap_body_cells_to: nil)

      @sources = sources
      @header_frequency = header_frequency
      @wrap_header_cells_to = wrap_header_cells_to
      @wrap_body_cells_to = wrap_body_cells_to

      @default_column_width = (column_width || DEFAULT_COLUMN_WIDTH)

      @columns = []
      columns.each { |item| add_column(item) }

      yield self if block_given?
    end

    # Adds a column to the Table.
    #
    # @param [Symbol, String] label A unique identifier for this column, which by default will
    #   also be used as the column header text (see also the header param). If the
    #   extractor argument is not also provided, then the label argument should correspond to
    #   a method to be called on each item in the table sources to provide the content
    #   for this column.
    #
    # @param [nil, #to_s] header (nil) Text to be displayed in the column header. If passed nil,
    #   the column's label will also be used as its header text.
    # @param [:left, :center, :right] align_header (:center) Specifies how the header text
    #   should be aligned.
    # @param [:left, :center, :right, nil] align_body (nil) Specifies how the cell body contents
    #   should be aligned. Possible If <tt>nil</tt> is passed, then the alignment is determined
    #   by the type of the cell value, with numbers aligned right, booleans center-aligned, and
    #   other values left-aligned. Note header text alignment is configured separately using the
    #   :align_header param.
    # @param [Fixnum] width (nil) Specifies the width of the column, excluding padding. If
    #   nil, then the column will take the width provided by the `column_width` param
    #   with which the Table was initialized.
    # @param [#to_proc] formatter (:to_s.to_proc) A lambda or other callable object that
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
    def add_column(label, header: nil, align_header: :center, align_body: nil,
      width: nil, formatter: :to_s.to_proc, &extractor)

      @columns << Column.new(
        label: label.to_sym,
        header: (header || label).to_s,
        align_header: align_header,
        align_body: align_body,
        width: (width || @default_column_width),
        formatter: formatter,
        extractor: (extractor || label.to_proc)
      )
    end

    # @return [String] a graphical "ASCII" representation of the Table, suitable for
    #   display in a fixed-width font.
    def to_s
      if @columns.any?
        join_lines(map(&:to_s))
      else
        ""
      end
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
      cells = @columns.map(&:header_subcells)
      format_row(cells, @wrap_header_cells_to)
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
      inner = @columns.map { |column| surround(column.horizontal_rule, HORIZONTAL_RULE_CHARACTER) }
      surround_join(inner, CORNER_CHARACTER)
    end

    # Reset all the column widths so that each column is *just* wide enough to accommodate
    # its header text as well as the formatted content of each its cells for the entire
    # collection, together with a single character of padding on either side of the column,
    # without any wrapping.
    #
    # Note that calling this method will cause the entire source Enumerable to
    # be traversed and all the column extractors and formatters to be applied in order
    # to calculate the required widths.
    #
    # @param [nil, Numeric] max_table_width (nil) If provided, stops the total table
    #   width (including padding and borders) from expanding beyond this number of characters.
    #   Width is deducted from columns if required to achieve this, with one character progressively
    #   deducted from the width of the widest column until the target is reached. When the
    #   table is printed, wrapping or truncation will then occur in these columns as required
    #   (depending on how they were configured). Note that regardless of the value passed to
    #   max_table_width, the table will always be left wide enough to accommodate at least
    #   1 character's width of content, 1 character of left padding and 1 character of right padding
    #   in each column, together with border characters (1 on each side of the table and 1 between
    #   adjacent columns). I.e. there is a certain width below width the Table will refuse to
    #   shrink itself.
    #
    # @return [Table] the Table itself
    def shrinkwrap!(max_table_width: nil)
      return self if columns.none?

      wrapped_width = -> (str) { str.split($/).map(&:length).max || 1 }

      columns.each do |column|
        column.width = wrapped_width.call(column.header)
      end

      @sources.each do |source|
        columns.each do |column|
          width = wrapped_width.call(column.formatted_cell_content(source))
          column.width = width if width > column.width
        end
      end

      if max_table_width
        total_columns_width = columns.inject(0) { |sum, column| sum + column.width }
        total_padding = columns.count * 2
        total_borders = columns.count + 1
        unadjusted_table_width = total_columns_width + total_padding + total_borders

        # Ensure max table width is at least wide enough to accommodate table borders and padding
        # and one character of content.
        min_table_width = total_padding + total_borders + columns.count
        max_table_width = min_table_width if min_table_width > max_table_width

        required_reduction = [unadjusted_table_width - max_table_width, 0].max

        required_reduction.times do
          widest_column = columns.inject(columns.first) do |widest, column|
            column.width >= widest.width ? column : widest
          end

          widest_column.width -= 1
        end
      end

      self
    end

    # @!visibility private
    def formatted_body_row(source, with_header: false)
      cells = @columns.map { |column| column.body_subcells(source) }
      inner = format_row(cells, @wrap_body_cells_to)
      if with_header
        join_lines([horizontal_rule, formatted_header, horizontal_rule, inner])
      else
        inner
      end
    end

    private

    # @!visibility private
    def body_row(source, with_header: false)
      Row.new(self, source, with_header: with_header)
    end

    # @!visibility private
    #
    # Formats a single header row or body row as a String.
    #
    # @param [String[][]] cells an Array of Array-of-Strings, each of which represents a
    #   "stack" of "subcells". Each such stack represents the wrapped content of a given
    #   "cell" in this row, from the top down, one String for each "line".
    #   Each String includes the spaces, if any, on either side required for the
    #   "internal padding" of the cell to carry out the cell content alignment -- but
    #   does not include the single character of padding around each column.
    # @param [Fixnum] wrap_cells_to the number of "lines" of wrapped content to allow
    #   before truncating.
    # @return [String] the entire formatted row including all padding and borders.
    def format_row(cells, wrap_cells_to)

      # Create an array of "cell stacks", each of which is an array of strings that
      # will be stacked on top of each other to form a wrapped cell.
      cell_stacks = cells.map do |raw_subcells|
        num_raw_subcells = raw_subcells.size
        num_wrapped_subcells = (wrap_cells_to || num_raw_subcells)

        truncated = (num_raw_subcells > num_wrapped_subcells)
        subcells = raw_subcells[0...num_wrapped_subcells]

        subcells.map.with_index do |subcell, i|
          subcell_truncated = (truncated && (i == subcells.size - 1))
          lpad = PADDING_CHARACTER
          rpad = (subcell_truncated ? TRUNCATION_INDICATOR : PADDING_CHARACTER)
          "#{lpad}#{subcell}#{rpad}"
        end
      end

      max_cell_stack_height = cell_stacks.map(&:size).max || 1

      # A subrow is a string representing a single horizontal slice of this row that's
      # strictly one character high.
      subrows = (0...max_cell_stack_height).map do |subrow_index|
        cell_stacks.map.with_index do |cell_stack, column_index|
          if subrow_index < cell_stack.size
            # This cell stack is at least as "deep" as the subrow we're on. So just
            # grab the subcell for this subrow from this cell stack.
            cell_stack[subrow_index]
          else
            # This cell stack is not "deep" enough. So we make an empty subcell to
            # add to this subrow for this column
            surround(' ' * @columns[column_index].width, PADDING_CHARACTER)
          end
        end
      end

      # Join each subrow with border characters, then join these with newlines, to form
      # the wrapped, formatted row as a single string.
      join_lines(subrows.map { |subrow| surround_join(subrow, VERTICAL_RULE_CHARACTER) })
    end

    # @!visibility private
    def surround(str, ch0)
      "#{ch0}#{str}#{ch0}"
    end

    # @!visibility private
    def surround_join(arr, ch)
      surround(arr.join(ch), ch)
    end

    # @!visibility private
    def join_lines(lines)
      lines.join($/)  # join strings with cross-platform newline
    end
  end
end
