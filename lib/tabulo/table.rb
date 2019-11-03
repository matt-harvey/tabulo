require "tty-screen"
require "unicode/display_width"

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
    DEFAULT_TRUNCATION_INDICATOR = "~"

    # @!visibility private
    PADDING_CHARACTER = " "

    # @!visibility private
    attr_reader :column_registry

    # @return [Enumerable] the underlying enumerable from which the table derives its data
    attr_accessor :sources

    # @param [Enumerable] sources the underlying Enumerable from which the table will derive its data
    # @param [Array[Symbol]] columns Specifies the initial columns. The Symbols provided must
    #   be unique. Each element of the Array  will be used to create a column whose content is
    #   created by calling the corresponding method on each element of sources. Note
    #   the {#add_column} method is a much more flexible way to set up columns on the table.
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
    # @param [nil, String] truncation_indicator Determines the character used to indicate that a
    #   cell's content has been truncated. If omitted or passed <tt>nil</tt>,
    #   defaults to {DEFAULT_TRUNCATION_INDICATOR}. If passed something other than <tt>nil</tt> or
    #   a single-character String, raises {InvalidTruncationIndicatorError}.
    # @param [nil, Integer] column_padding Determines the amount of blank space with which to pad either
    #   of each column. Defaults to 1.
    # @param [:left, :right, :center] align_header (:center) Determines the alignment of header text
    #   for columns in this Table. Can be overridden for individual columns using the
    #   <tt>align_header</tt> option passed to {#add_column}
    # @param [:left, :right, :center, :auto] align_body (:auto) Determines the alignment of body cell
    #   (i.e. non-header) content within columns in this Table. Can be overridden for individual columns
    #   using the <tt>align_body</tt> option passed to {#add_column}. If passed <tt>:auto</tt>,
    #   alignment is determined by cell content, with numbers aligned right, booleans
    #   center-aligned, and other values left-aligned.
    # @param [:ascii, :markdown, :modern, :blank] border [:ascii] Determines the characters used
    #   for the Table border, including both the characters around the outside of table, and the lines drawn
    #   within the table to separate columns from each other and the header row from the Table body.
    #   Possible values are:
    #   - `:ascii`     Uses ASCII characters only
    #   - `:markdown`  Produces as a GitHub-flavoured Markdown table
    #   - `:modern`    Uses non-ASCII Unicode characters to render a border with smooth continuous lines
    #   - `:blank`     No border characters are rendered
    #   - `:classic`   Like `:ascii`, but does not have a horizontal line at the bottom of the
    #                  table. This reproduces the default behaviour in `tabulo` v1.
    # @param [nil, #to_proc] border_styler (nil) A lambda or other callable object taking
    #   a single parameter, representing a section of the table's borders (which for this purpose
    #   include any horizontal and vertical lines inside the table), and returning a string.
    #   If passed <tt>nil</tt>, then no additional styling will be applied to borders. If passed a
    #   callable, then that callable will be called for each border section, with the
    #   resulting string rendered in place of that border. The extra width of the string returned by the
    #   {border_styler} is not taken into consideration by the internal table rendering calculations
    #   Thus it can be used to apply ANSI escape codes to border characters, to colour the borders
    #   for example, without breaking the table formatting.
    # @return [Table] a new {Table}
    # @raise [InvalidColumnLabelError] if non-unique Symbols are provided to columns.
    # @raise [InvalidBorderError] if invalid option passed to `border` parameter.
    def initialize(sources, *columns, column_width: nil, column_padding: nil, header_frequency: :start,
      wrap_header_cells_to: nil, wrap_body_cells_to: nil, truncation_indicator: nil, align_header: :center,
      align_body: :auto, border: :ascii, border_styler: nil)

      @sources = sources
      @header_frequency = header_frequency
      @wrap_header_cells_to = wrap_header_cells_to
      @wrap_body_cells_to = wrap_body_cells_to
      @default_column_width = (column_width || DEFAULT_COLUMN_WIDTH)
      @column_padding = (column_padding || DEFAULT_COLUMN_PADDING)
      @align_header = align_header
      @align_body = align_body

      @border = border
      @border_styler = border_styler
      @border_instance = Border.from(@border, @border_styler)

      @truncation_indicator = validate_character(truncation_indicator,
        DEFAULT_TRUNCATION_INDICATOR, InvalidTruncationIndicatorError, "truncation indicator")

      @column_registry = { }
      columns.each { |item| add_column(item) }

      yield self if block_given?
    end

    # Adds a column to the Table.
    #
    # @param [Symbol, String, Integer] label A unique identifier for this column, which by
    #   default will also be used as the column header text (see also the header param). If the
    #   extractor argument is not also provided, then the label argument should correspond to
    #   a method to be called on each item in the table sources to provide the content
    #   for this column. If a String is passed as the label, then it will be converted to
    #   a Symbol for the purpose of serving as this label.
    # @param [nil, #to_s] header (nil) Text to be displayed in the column header. If passed nil,
    #   the column's label will also be used as its header text.
    # @param [:left, :center, :right, nil] align_header (nil) Specifies how the header text
    #   should be aligned. If <tt>nil</tt> is passed, then the alignment is determined
    #   by the Table-level setting passed to the <tt>align_header</tt> (which itself defaults
    #   to <tt>:center</tt>). Otherwise, this option determines the alignment of the header
    #   content for this column.
    # @param [:left, :center, :right, :auto, nil] align_body (nil) Specifies how the cell body contents
    #   should be aligned. If <tt>nil</tt> is passed, then the alignment is determined
    #   by the Table-level setting passed to the <tt>align_body</tt> option on Table initialization
    #   (which itself defaults to <tt>:auto</tt>). Otherwise this option determines the alignment of
    #   this column. If <tt>:auto</tt> is passed, the alignment is determined by the type of the cell
    #   value, with numbers aligned right, booleans center-aligned, and other values left-aligned.
    #   Note header text alignment is configured separately using the :align_header param.
    # @param [Integer] width (nil) Specifies the width of the column, excluding padding. If
    #   nil, then the column will take the width provided by the `column_width` param
    #   with which the Table was initialized.
    # @param [#to_proc] formatter (:to_s.to_proc) A lambda or other callable object that
    #   will be passed the calculated value of each cell to determine how it should be displayed. This
    #   is distinct from the extractor (see below). For example, if the extractor for this column
    #   generates a Date, then the formatter might format that Date in a particular way.
    #   If no formatter is provided, then <tt>.to_s</tt> will be called on
    #   the extracted value of each cell to determine its displayed content.
    # @param [nil, #to_proc] styler (nil) A lambda or other callable object that will be passed
    #   two arguments: the calculated value of the cell (prior to the {formatter} being applied);
    #   and a string representing a single formatted line within the cell. For example, if the
    #   cell content is wrapped over three lines, then for that cell, the {styler} will be called
    #   three times, once for each line of content within the cell. If passed <tt>nil</tt>, then
    #   no additional styling will be applied to the cell content (other than what was already
    #   applied by the {formatter}). If passed a callable, then that callable will be called for
    #   each line of content within the cell, and the resulting string rendered in place of that
    #   line. The {styler} option differs from the {formatter} option in that the extra width of the
    #   string returned by {styler} is not taken into consideration by the internal table and
    #   cell width calculations involved in rendering the table. Thus it can be used to apply
    #   ANSI escape codes to cell content, to colour the cell content for example, without
    #   breaking the table formatting.
    #   Note that if the content of a cell is truncated, then the whatever styling is applied by the
    #   {styler} to the cell content will also be applied to the truncation indicator character.
    # @param [nil, #to_proc] header_styler (nil) A lambda or other callable object taking
    #   a single parameter, representing a single line of within the header content for
    #   this column. For example, if the header cell content is wrapped over three lines, then
    #   the {header_styler} will be called once for each line. If passed <tt>nil</tt>, then
    #   no additional styling will be applied to the header cell content. If passed a callable,
    #   then that callable will be called for each line of content within the header cell, and the
    #   resulting string rendered in place of that line. The extra width of the string returned by the
    #   {header_styler} is not taken into consideration by the internal table and
    #   cell width calculations involved in rendering the table. Thus it can be used to apply
    #   ANSI escape codes to header cell content, to colour the cell content for example, without
    #   breaking the table formatting.
    #   Note that if the header content is truncated, then any {header_styler} will be applied to the
    #   truncation indicator character as well as to the truncated content.
    # @param [#to_proc] extractor A block or other callable
    #   that will be passed each of the Table sources to determine the value in each cell of this
    #   column. If this is not provided, then the column label will be treated as a method to be
    #   called on each source item to determine each cell's value.
    # @raise [InvalidColumnLabelError] if label has already been used for another column in this
    #   Table. (This is case-sensitive, but is insensitive to whether a String or Symbol is passed
    #   to the label parameter.)
    def add_column(label, header: nil, align_header: nil, align_body: nil,
      width: nil, formatter: :to_s.to_proc, styler: nil, header_styler: nil, &extractor)

      column_label =
        case label
        when Integer, Symbol
          label
        when String
          label.to_sym
        end

      if column_registry.include?(column_label)
        raise InvalidColumnLabelError, "Column label already used in this table."
      end

      @column_registry[column_label] =
        Column.new(
          header: (header || label).to_s,
          align_header: align_header || @align_header,
          align_body: align_body || @align_body,
          width: (width || @default_column_width),
          formatter: formatter,
          extractor: (extractor || label.to_proc),
          styler: styler,
          header_styler: header_styler,
          truncation_indicator: @truncation_indicator,
          padding_character: PADDING_CHARACTER,
        )
    end

    # @return [String] a graphical "ASCII" representation of the Table, suitable for
    #   display in a fixed-width font.
    def to_s
      if column_registry.any?
        bottom_edge = horizontal_rule(:bottom)
        rows = map(&:to_s)
        bottom_edge.empty? ? join_lines(rows) : join_lines(rows + [bottom_edge])
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
        header =
          case @header_frequency
          when :start
            :top if index == 0
          when Integer
            if index == 0
              :top
            elsif index % @header_frequency == 0
              :middle
            end
          else
            @header_frequency
          end
        yield body_row(source, header: header)
      end
    end

    # @return [String] an "ASCII" graphical representation of the Table column headers.
    def formatted_header
      cells = column_registry.map { |_, column| column.header_cell }
      format_row(cells, @wrap_header_cells_to)
    end

    # @param [:top, :middle, :bottom] align_body (:bottom) Specifies the position
    #   for which the resulting horizontal dividing line is intended to be printed.
    #   This determines the border characters that are used to construct the line.
    # @return [String] an "ASCII" graphical representation of a horizontal
    #   dividing line suitable for printing at the top, bottom or middle of the
    #   table.
    # @example Print a horizontal divider between each pair of rows, and again
    #   at the bottom:
    #
    #   table.each_with_index do |row, i|
    #     puts table.horizontal_rule(:middle) unless i == 0
    #     puts row
    #   end
    #   puts table.horizontal_rule(:bottom)
    #
    # It may be that `:top`, `:middle` and `:bottom` all look the same. Whether
    # this is the case depends on the characters used for the table border.
    def horizontal_rule(position = :bottom)
      column_widths = column_registry.map { |_, column| column.width + @column_padding * 2 }
      @border_instance.horizontal_rule(column_widths, position)
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
          width = wrapped_width(column.body_cell(source).formatted_content)
          column.width = width if width > column.width
        end
      end

      if max_table_width
        max_table_width = TTY::Screen.width if max_table_width == :auto
        shrink_to(max_table_width)
      end

      self
    end

    # Creates a new {Table} from the current Table, transposed, that is rotated 90 degrees,
    # relative to the current Table, so that the header names of the current Table form the
    # content of left-most column of the new Table, and each column thereafter corresponds to one of the
    # elements of the current Table's <tt>sources</tt>, with the header of that column being the String
    # value of that element.
    #
    # @example
    #   puts Tabulo::Table.new(-1..1, :even?, :odd?, :abs).transpose
    #     # => +-------+--------------+--------------+--------------+
    #     #    |       |      -1      |       0      |       1      |
    #     #    +-------+--------------+--------------+--------------+
    #     #    | even? |     false    |     true     |     false    |
    #     #    |  odd? |     true     |     false    |     true     |
    #     #    |   abs |            1 |            0 |            1 |
    #
    # @param [Hash] opts Options for configuring the new, transposed {Table}.
    #   The following options are the same as the keyword params for the {#initialize} method for
    #   {Table}: <tt>column_width</tt>, <tt>column_padding</tt>, <tt>header_frequency</tt>,
    #   <tt>wrap_header_cells_to</tt>, <tt>wrap_body_cells_to</tt>, <tt>border</tt>,
    #   <tt>border_styler</tt>, <tt>truncation_indicator</tt>, <tt>align_header</tt>, <tt>align_body</tt>.
    #   These are applied in the same way as documented for {#initialize}, when creating the
    #   new, transposed Table. Any options not specified explicitly in the call to {#transpose}
    #   will inherit their values from the original {Table} (with the exception of settings
    #   for the left-most column, containing the field names, which are determined as described
    #   below). In addition, the following options also apply to {#transpose}:
    # @option opts [nil, Integer] :field_names_width Determines the width of the left-most column of the
    #   new Table, which contains the names of "fields" (corresponding to the original Table's
    #   column headings). If this is not provided, then by default this column will be made just
    #   wide enough to accommodate its contents.
    # @option opts [String] :field_names_header ("") By default the left-most column will have a
    #   blank header; but this can be overridden by passing a String to this option.
    # @option opts [:left, :center, :right] :field_names_header_alignment (:right) Specifies how the
    #   header text of the left-most column (if it has header text) should be aligned.
    # @option opts [:left, :center, :right] :field_names_body_alignment (:right) Specifies how the
    #   body text of the left-most column should be aligned.
    # @option opts [#to_proc] :headers (:to_s.to_proc) A lambda or other callable object that
    #   will be passed in turn each of the elements of the current Table's <tt>sources</tt>
    #   Enumerable, to determine the text to be displayed in the header of each column of the
    #   new Table (other than the left-most column's header, which is determined as described
    #   above).
    # @return [Table] a new {Table}
    # @raise [InvalidBorderError] if invalid argument passed to `border` parameter.
    def transpose(opts = {})
      default_opts = [:column_width, :column_padding, :header_frequency, :wrap_header_cells_to,
        :wrap_body_cells_to, :truncation_indicator, :align_header, :align_body, :border,
        :border_styler].map do |sym|
        [sym, instance_variable_get("@#{sym}")]
      end.to_h

      initializer_opts = default_opts.merge(Util.slice_hash(opts, *default_opts.keys))
      default_extra_opts = { field_names_width: nil, field_names_header: "",
        field_names_body_alignment: :right, field_names_header_alignment: :right, headers: :to_s.to_proc }
      extra_opts = default_extra_opts.merge(Util.slice_hash(opts, *default_extra_opts.keys))

      # The underlying enumerable for the new table, is the columns of the original table.
      fields = column_registry.values

      Table.new(fields, **initializer_opts) do |t|

        # Left hand column of new table, containing field names
        width_opt = extra_opts[:field_names_width]
        field_names_width = (width_opt.nil? ? fields.map { |f| f.header.length }.max : width_opt)

        t.add_column(:dummy, header: extra_opts[:field_names_header], width: field_names_width, align_header:
          extra_opts[:field_names_header_alignment], align_body: extra_opts[:field_names_body_alignment], &:header)

        # Add a column to the new table for each of the original table's sources
        sources.each_with_index do |source, i|
          t.add_column(i, header: extra_opts[:headers].call(source)) do |original_column|
            original_column.body_cell_value(source)
          end
        end
      end
    end

    # @!visibility private
    def formatted_body_row(source, header: nil)
      cells = column_registry.map { |_, column| column.body_cell(source) }
      inner = format_row(cells, @wrap_body_cells_to)
      if header
        join_lines([
          horizontal_rule(header == :top ? :top : :middle),
          formatted_header,
          horizontal_rule(:middle),
          inner,
        ].reject(&:empty?))
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
    def body_row(source, header: nil)
      Row.new(self, source, header: header)
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
      max_cell_height = cells.map(&:height).max
      row_height = ([wrap_cells_to, max_cell_height].compact.min || 1)
      subcell_stacks = cells.map { |cell| cell.padded_truncated_subcells(row_height, @column_padding) }
      subrows = subcell_stacks.transpose.map do |subrow_components|
        @border_instance.join_cell_contents(subrow_components)
      end

      join_lines(subrows)
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
        if Unicode::DisplayWidth.of(c) != 1
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
      segments.inject(1) do |longest_length_so_far, segment|
        length = Unicode::DisplayWidth.of(segment)
        longest_length_so_far > length ? longest_length_so_far : length
      end
    end
  end
end
