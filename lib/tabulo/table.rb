require "tty-screen"

module Tabulo

  # Represents a table primarily intended for "pretty-printing" in a fixed-width font.
  #
  # A Table is also an Enumerable, of which each element is a {Row}.
  class Table
    include Enumerable

    # @!visibility public
    DEFAULT_COLUMN_WIDTH = 12

    # @!visibility public
    DEFAULT_COLUMN_PADDING = 1

    # @!visibility public
    DEFAULT_HORIZONTAL_RULE_CHARACTER = "-"

    # @!visibility public
    DEFAULT_VERTICAL_RULE_CHARACTER = "|"

    # @!visibility public
    DEFAULT_INTERSECTION_CHARACTER = "+"

    # @!visibility public
    DEFAULT_TRUNCATION_INDICATOR = "~"

    # @!visibility private
    PADDING_CHARACTER = " "

    # @!visibility private
    attr_reader :column_registry

    # @return [Enumerable] the underlying enumerable from which the table derives its data
    attr_accessor :sources

    # @param [Enumerable] sources the underlying Enumerable from which the table will derive its data
    # @param [Array[Symbol]] cols Specifies the initial columns. The Symbols provided must
    #   be unique. Each element of the Array  will be used to create a column whose content is
    #   created by calling the corresponding method on each element of sources. Note
    #   the {#add_column} method is a much more flexible way to set up columns on the table.
    # @param [Array[Symbol]] columns <b>DEPRECATED</b> Use {cols} instead.
    # @param [Integer, nil] column_width The default column width for columns in this
    #   table, not excluding padding. If <tt>nil</tt>, then {DEFAULT_COLUMN_WIDTH} will be used.
    # @param [:start, nil, Integer] header_frequency Controls the display of column headers.
    #   If passed <tt>:start</tt>, headers will be shown at the top of the table only. If passed <tt>nil</tt>,
    #   headers will not be shown. If passed an Integer N (> 0), headers will be shown at the top of the table,
    #   then repeated every N rows.
    # @param [nil, Integer] wrap_header_cells_to Controls wrapping behaviour for header
    #   cells if the content thereof is longer than the column's fixed width. If passed <tt>nil</tt> (default),
    #   content will be wrapped for as many rows as required to accommodate it. If passed an Integer N (> 0),
    #   content will be wrapped up to N rows and then truncated thereafter.
    # @param [nil, Integer] wrap_body_cells_to Controls wrapping behaviour for table cells (excluding
    #   headers), if their content is longer than the column's fixed width. If passed <tt>nil</tt>, content will
    #   be wrapped for as many rows as required to accommodate it. If passed an Integer N (> 0), content will be
    #   wrapped up to N rows and then truncated thereafter.
    #   headers), if their content is longer than the column's fixed width. If passed <tt>nil</tt>, content will
    #   be wrapped for as many rows as required to accommodate it. If passed an Integer N (> 0), content will be
    #   wrapped up to N rows and then truncated thereafter.
    # @param [nil, String] horizontal_rule_character Determines the character used to draw
    #   horizontal lines where required in the table. If omitted or passed <tt>nil</tt>, defaults to
    #   {DEFAULT_HORIZONTAL_RULE_CHARACTER}. If passed something other than <tt>nil</tt> or a single-character
    #   String, raises {InvalidHorizontalRuleCharacterError}.
    # @param [nil, String] vertical_rule_character Determines the character used to draw
    #   vertical lines where required in the table. If omitted or passed <tt>nil</tt>, defaults to
    #   {DEFAULT_VERTICAL_RULE_CHARACTER}. If passed something other than <tt>nil</tt> or a single-character
    #   String, raises {InvalidVerticalRuleCharacterError}.
    # @param [nil, String] intersection_character Determines the character used to draw
    #   line intersections and corners where required in the table. If omitted or passed <tt>nil</tt>,
    #   defaults to {DEFAULT_INTERSECTION_CHARACTER}. If passed something other than <tt>nil</tt> or
    #   a single-character String, raises {InvalidIntersectionCharacterError}.
    # @param [nil, String] truncation_indicator Determines the character used to indicate that a
    #   cell's content has been truncated. If omitted or passed <tt>nil</tt>,
    #   defaults to {DEFAULT_TRUNCATION_INDICATOR}. If passed something other than <tt>nil</tt> or
    #   a single-character String, raises {InvalidTruncationIndicatorError}.
    # @param [nil, Integer] column_padding Determines the amount of blank space with which to pad either
    #   of each column. Defaults to 1.
    # @return [Table] a new {Table}
    # @raise [InvalidColumnLabelError] if non-unique Symbols are provided to columns.
    # @raise [InvalidHorizontalRuleCharacterError] if invalid argument passed to horizontal_rule_character.
    # @raise [InvalidVerticalRuleCharacterError] if invalid argument passed to vertical_rule_character.
    def initialize(sources, *cols, columns: [], column_width: nil, column_padding: nil, header_frequency: :start,
      wrap_header_cells_to: nil, wrap_body_cells_to: nil, horizontal_rule_character: nil,
      vertical_rule_character: nil, intersection_character: nil, truncation_indicator: nil)

      if columns.any?
        warn "[DEPRECATION] `columns` option to Tabulo::Table#initialize is deprecated. Please use the variable length parameter `cols` instead."
      end

      @sources = sources
      @header_frequency = header_frequency
      @wrap_header_cells_to = wrap_header_cells_to
      @wrap_body_cells_to = wrap_body_cells_to
      @default_column_width = (column_width || DEFAULT_COLUMN_WIDTH)
      @column_padding = (column_padding || DEFAULT_COLUMN_PADDING)

      @horizontal_rule_character = validate_character(horizontal_rule_character,
        DEFAULT_HORIZONTAL_RULE_CHARACTER, InvalidHorizontalRuleCharacterError, "horizontal rule character")
      @vertical_rule_character = validate_character(vertical_rule_character,
        DEFAULT_VERTICAL_RULE_CHARACTER, InvalidVerticalRuleCharacterError, "vertical rule character")
      @intersection_character = validate_character(intersection_character,
        DEFAULT_INTERSECTION_CHARACTER, InvalidIntersectionCharacterError, "intersection character")
      @truncation_indicator = validate_character(truncation_indicator,
        DEFAULT_TRUNCATION_INDICATOR, InvalidTruncationIndicatorError, "truncation indicator")

      @column_registry = { }
      cols.each { |item| add_column(item) }
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
    # @param [nil, #to_s] header (nil) Text to be displayed in the column header. If passed nil,
    #   the column's label will also be used as its header text.
    # @param [:left, :center, :right] align_header (:center) Specifies how the header text
    #   should be aligned.
    # @param [:left, :center, :right, nil] align_body (nil) Specifies how the cell body contents
    #   should be aligned. Possible If <tt>nil</tt> is passed, then the alignment is determined
    #   by the type of the cell value, with numbers aligned right, booleans center-aligned, and
    #   other values left-aligned. Note header text alignment is configured separately using the
    #   :align_header param.
    # @param [Integer] width (nil) Specifies the width of the column, excluding padding. If
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
    # @raise [InvalidColumnLabelError] if label has already been used for another column in this
    #   Table. (This is case-sensitive, but is insensitive to whether a String or Symbol is passed
    #   to the label parameter.)
    def add_column(label, header: nil, align_header: :center, align_body: nil,
      width: nil, formatter: :to_s.to_proc, &extractor)

      column_label = label.to_sym

      if column_registry.include?(column_label)
        raise InvalidColumnLabelError, "Column label already used in this table."
      end

      @column_registry[column_label] =
        Column.new(
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
      if column_registry.any?
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
          when Integer
            index % @header_frequency == 0
          else
            @header_frequency
          end
        yield body_row(source, with_header: include_header)
      end
    end

    # @return [String] an "ASCII" graphical representation of the Table column headers.
    def formatted_header
      cells = column_registry.map { |_, column| column.header_subcells }
      format_row(cells, @wrap_header_cells_to)
    end

    # @return [String] an "ASCII" graphical representation of a horizontal
    #   dividing line suitable for printing at any point in the table.
    # @example Print a horizontal divider after every row:
    #   table.each do |row|
    #     puts row
    #     puts table.horizontal_rule
    #   end
    #
    def horizontal_rule
      inner = column_registry.map do |_, column|
        @horizontal_rule_character * (column.width + @column_padding * 2)
      end
      surround_join(inner, @intersection_character)
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
    # Note also that this method causes column widths to be fixed as appropriate to the
    # formatted cell contents given the state of the source Enumerable at the point it
    # is called. If the source Enumerable changes between that point, and the point when
    # the Table is printed, then columns will *not* be resized yet again on printing.
    #
    # @param [nil, Numeric] max_table_width (:auto) With no args, or if passed <tt>:auto</tt>,
    #   stops the total table width (including padding and borders) from expanding beyond the
    #   bounds of the terminal screen.
    #   If passed <tt>nil</tt>, the table width will not be capped.
    #   Width is deducted from columns if required to achieve this, with one character progressively
    #   deducted from the width of the widest column until the target is reached. When the
    #   table is printed, wrapping or truncation will then occur in these columns as required
    #   (depending on how they were configured).
    #   Note that regardless of the value passed to max_table_width, the table will always be left wide
    #   enough to accommodate at least 1 character's width of content, 1 character of left padding and
    #   1 character of right padding in each column, together with border characters (1 on each side
    #   of the table and 1 between adjacent columns). I.e. there is a certain width below width the
    #   Table will refuse to shrink itself.
    # @return [Table] the Table itself
    def pack(max_table_width: :auto)
      return self if column_registry.none?
      columns = column_registry.values

      columns.each { |column| column.width = wrapped_width(column.header) }

      @sources.each do |source|
        columns.each do |column|
          width = wrapped_width(column.formatted_cell_content(source))
          column.width = width if width > column.width
        end
      end

      if max_table_width
        max_table_width = TTY::Screen.width if max_table_width == :auto
        shrink_to(max_table_width)
      end

      self
    end

    # @deprecated Use {#pack} instead.
    #
    # Reset all the column widths so that each column is *just* wide enough to accommodate
    # its header text as well as the formatted content of each its cells for the entire
    # collection, together with a single character of padding on either side of the column,
    # without any wrapping.
    #
    # Note that calling this method will cause the entire source Enumerable to
    # be traversed and all the column extractors and formatters to be applied in order
    # to calculate the required widths.
    #
    # Note also that this method causes column widths to be fixed as appropriate to the
    # formatted cell contents given the state of the source Enumerable at the point it
    # is called. If the source Enumerable changes between that point, and the point when
    # the Table is printed, then columns will *not* be resized yet again on printing.
    #
    # @param [nil, Numeric] max_table_width (nil) If provided, stops the total table
    #   width (including padding and borders) from expanding beyond this number of characters.
    #   If passed <tt>:auto</tt>, the table width will automatically be capped at the current
    #   terminal width.
    #   Width is deducted from columns if required to achieve this, with one character progressively
    #   deducted from the width of the widest column until the target is reached. When the
    #   table is printed, wrapping or truncation will then occur in these columns as required
    #   (depending on how they were configured).
    #   Note that regardless of the value passed to max_table_width, the table will always be left wide
    #   enough to accommodate at least 1 character's width of content, 1 character of left padding and
    #   1 character of right padding in each column, together with border characters (1 on each side
    #   of the table and 1 between adjacent columns). I.e. there is a certain width below width the
    #   Table will refuse to shrink itself.
    # @return [Table] the Table itself
    def shrinkwrap!(max_table_width: nil)
      warn "[DEPRECATION] `Tabulo::Table#shrinkwrap!` is deprecated. Please use `#pack` instead."
      pack(max_table_width: max_table_width)
    end

    # @!visibility private
    def formatted_body_row(source, with_header: false)
      cells = column_registry.map { |_, column| column.body_subcells(source) }
      inner = format_row(cells, @wrap_body_cells_to)
      if with_header
        join_lines([horizontal_rule, formatted_header, horizontal_rule, inner])
      else
        inner
      end
    end

    private

    # @!visibility private
    def shrink_to(max_table_width)
      columns = column_registry.values
      total_columns_width = columns.inject(0) { |sum, column| sum + column.width }
      total_padding = column_registry.count * @column_padding * 2
      total_borders = column_registry.count + 1
      unadjusted_table_width = total_columns_width + total_padding + total_borders

      # Ensure max table width is at least wide enough to accommodate table borders and padding
      # and one character of content.
      min_table_width = total_padding + total_borders + column_registry.count
      max_table_width = min_table_width if min_table_width > max_table_width
      required_reduction = [unadjusted_table_width - max_table_width, 0].max

      required_reduction.times do
        widest_column = columns.inject(columns.first) do |widest, column|
          column.width >= widest.width ? column : widest
        end

        widest_column.width -= 1
      end
    end

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
    # @param [Integer] wrap_cells_to the number of "lines" of wrapped content to allow
    #   before truncating.
    # @return [String] the entire formatted row including all padding and borders.
    def format_row(cells, wrap_cells_to)
      row_height = ([wrap_cells_to, cells.map(&:size).max].compact.min || 1)

      subrows = (0...row_height).map do |subrow_index|
        subrow_components = cells.zip(column_registry.values).map do |cell, column|
          num_subcells = cell.size
          cell_truncated = (num_subcells > row_height)
          append_truncator = (cell_truncated && subrow_index + 1 == row_height)

          lpad = PADDING_CHARACTER * @column_padding
          rpad =
            if append_truncator && @column_padding != 0
              @truncation_indicator + PADDING_CHARACTER * (@column_padding - 1)
            else
              PADDING_CHARACTER * @column_padding
            end

          inner =
            if subrow_index < num_subcells
              cell[subrow_index]
            else
              PADDING_CHARACTER * column.width
            end

          "#{lpad}#{inner}#{rpad}"
        end

        surround_join(subrow_components, @vertical_rule_character)
      end

      join_lines(subrows)
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

    # @!visibility private
    def validate_character(character, default, exception_class, message_fragment)
      case (c = (character || default))
      when nil
        ; # do nothing
      when String
        if c.length != 1
          raise exception_class, "#{message_fragment} is neither nil nor a single-character String"
        end
      else
        raise exception_class, "#{message_fragment} is neither nil nor a single-character String"
      end
      c
    end

    # @!visibility private
    # @return [Integer] the length of the longest segment of str when split by newlines
    def wrapped_width(str)
      segments = str.split($/)
      segments.inject(1) do |length, segment|
        length > segment.length ? length : segment.length
      end
    end
  end
end
