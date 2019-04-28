module Tabulo

  class Row
    include Enumerable

    # @return the element of the {Table}'s underlying enumerable to which this {Row} corresponds
    attr_reader :source

    # @!visibility private
    def initialize(table, source, with_header: true)
      @table = table
      @source = source
      @with_header = with_header
    end

    # Calls the given block once for each cell in the {Row}, passing that cell as parameter.
    # Each "cell" is just the calculated value for its column (pre-formatting) for this {Row}'s
    # source item.
    #
    # @example
    #   table = Tabulo::Table.new([1, 10], columns: %i(itself even?))
    #   row = table.first
    #   row.each do |cell|
    #     puts cell        # => 1,       => false
    #   end
    def each
      @table.column_registry.each do |_, column|
        yield column.body_cell_value(@source)
      end
    end

    # @return a String being an "ASCII" graphical representation of the {Row}, including
    #   any column headers that appear just above it in the {Table} (depending on where this Row is
    #   in the {Table} and how the {Table} was configured with respect to header frequency).
    def to_s
      if @table.column_registry.any?
        @table.formatted_body_row(@source, with_header: @with_header)
      else
        ""
      end
    end

    # @return a Hash representation of the {Row}, with column labels acting
    #   as keys and the calculated cell values (before formatting) providing the values.
    # @example
    #   table = Tabulo::Table.new([1, 10], columns: %i[itself even?])
    #   row = table.first
    #   row.to_h  # => { :itself => 1, :even? => false }
    def to_h
      @table.column_registry.map { |label, column| [label, column.body_cell_value(@source)] }.to_h
    end
  end
end
