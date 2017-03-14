module Tabulator

  class Column

    attr_reader :label, :truncate, :width

    def initialize(options)
      @label, @header = options[:label], options[:header]
      @truncate = options[:truncate]
      @align_header, @align_body = options[:align_header], options[:align_body]
      @extractor, @formatter = options[:extractor], options[:formatter]
      @width = options[:width]
      @horizontal_rule_character = options[:horizontal_rule_character]
    end

    def header_cell
      align_cell_content(@header, @align_header)
    end

    def horizontal_rule
      @horizontal_rule_character * @width
    end

    def body_cell(source)
      cell_datum = body_cell_value(source)
      formatted_cell_content = @formatter.call(cell_datum)
      real_alignment = @align_body || infer_alignment(cell_datum)
      align_cell_content(formatted_cell_content, real_alignment)
    end

    def body_cell_value(source)
      @extractor.call(source)
    end

    private

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
        else
          raise "Unrecognized alignment: #{real_alignment}"
        end

      "#{' ' * left_padding}#{content}#{' ' * right_padding}"
    end

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
