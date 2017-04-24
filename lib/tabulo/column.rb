module Tabulo

  class Column

    attr_reader :label, :width

    # Public: Initializes and returns a new Column.
    #
    # options - A Hash of options:
    #
    #          :label - A Symbol or String being a unique identifier for this Column.
    #                   If the :extractor option is not also provided, then the :label option
    #                   should correspond to a method to be called on each item in the table sources
    #                   to provide the content for this column.
    #
    #          :header       - The text to be displayed in the header for this Column.
    #
    #          :align_header - Specifies the alignment of the header text. Possible values are
    #                          <tt>:left</tt>, <tt>:center</tt> (the default) and <tt>right</tt>
    #
    #          :align_body   - Specifies how the cell body contents will be aligned. Possible
    #                          values are <tt>:left</tt>, <tt>:center</tt>, <tt>:right</tt>
    #                          and <tt>nil</tt>. If <tt>nil</tt> is passed (the default), then
    #                          the alignment is determined by the type of the cell value,
    #                          with numbers aligned right, booleans center-aligned, and
    #                          other values left-aligned. Note header text alignment is configured
    #                          separately using the :align_header option.
    #
    #          :extractor    - A callable, e.g. a block or lambda, that will be passed each of the
    #                          Table sources to determine the value in each cell of this Column. If
    #                          this is not provided, then the Column label will be treated as a
    #                          method to be called on each source item to determine each cell's
    #                          value.
    #
    #          :formatter    - A callable (e.g. a lambda) that will be passed the calculated
    #                          value of each cell to determine how it should be displayed. This
    #                          is distinct from the extractor (see below). For
    #                          example, if the extractor for this column generates a Date, then
    #                          the formatter might format that Date in a particular way.
    #                          If no formatter is provided, then <tt>.to_s</tt> will be called on
    #                          the extracted value of each cell to determine its displayed
    #                          content.
    #
    #          :width        - Specifies the width of the column, not including the single character
    #                          of padding. The default is given by Table::DEFAULT_COLUMN_WIDTH.
    def initialize(options)
      @label, @header = options[:label], options[:header]
      @align_header = options[:align_header] || :center
      @align_body = options[:align_body]  || nil
      @extractor = options[:extractor] || @label.to_proc
      @formatter = options[:formatter] || :to_s.to_proc
      @width = options[:width] || Table::DEFAULT_COLUMN_WIDTH
    end

    # Internal
    def header_cell
      align_cell_content(@header, @align_header)
    end

    # Internal
    def horizontal_rule
      Table::HORIZONTAL_RULE_CHARACTER * @width
    end

    # Internal
    def body_cell(source)
      cell_datum = body_cell_value(source)
      formatted_cell_content = @formatter.call(cell_datum)
      real_alignment = @align_body || infer_alignment(cell_datum)
      align_cell_content(formatted_cell_content, real_alignment)
    end

    # Internal
    def body_cell_value(source)
      @extractor.call(source)
    end

    private

    # Internal
    def align_cell_content(content, real_alignment)
      padding = [@width - content.length, 0].max
      left_padding, right_padding =
        case real_alignment
        when :center
          half_padding = padding / 2
          [padding - half_padding, half_padding]
        when :left
          [0, padding]
        when :right
          [padding, 0]
        end

      "#{' ' * left_padding}#{content}#{' ' * right_padding}"
    end

    # Internal
    def infer_alignment(cell_datum)
      case cell_datum
      when Numeric
        :right
      when TrueClass, FalseClass
        :center
      else
        :left
      end
    end
  end
end
