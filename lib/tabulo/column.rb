module Tabulo

  # @!visibility private
  class Column

    attr_reader :label, :width

    # @!visibility private
    def initialize(options)
      @label, @header = options[:label], options[:header]
      @align_header = options[:align_header] || :center
      @align_body = options[:align_body]  || nil
      @extractor = options[:extractor] || @label.to_proc
      @formatter = options[:formatter] || :to_s.to_proc
      @width = options[:width] || Table::DEFAULT_COLUMN_WIDTH
    end

    # @!visibility private
    def header_cell
      align_cell_content(@header, @align_header)
    end

    # @!visibility private
    def horizontal_rule
      Table::HORIZONTAL_RULE_CHARACTER * @width
    end

    # @!visibility private
    def body_cell(source)
      cell_datum = body_cell_value(source)
      formatted_cell_content = @formatter.call(cell_datum)
      real_alignment = @align_body || infer_alignment(cell_datum)
      align_cell_content(formatted_cell_content, real_alignment)
    end

    # @!visibility private
    def body_cell_value(source)
      @extractor.call(source)
    end

    private

    # @!visibility private
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

    # @!visibility private
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
