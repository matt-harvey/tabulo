module Tabulator

  class Row
    include Enumerable

    def initialize(table, source, options = { with_header: true })
      @table = table
      @source = source
      @with_header = options[:with_header]
    end

    def each
      @table._columns.each do |column|
        yield column.body_cell_value(@source)
      end
    end

    def to_s
      @table.formatted_body_row(@source, with_header: @with_header)
    end

    def to_h
      @table._columns.map(&:label).zip(to_a).to_h
    end
  end
end
