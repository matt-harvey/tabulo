module Tabulo

  class Row
    include Enumerable

    # @!visibility private
    def initialize(table, source, options = { with_header: true })
      @table = table
      @source = source
      @with_header = options[:with_header]
    end

    # Calls the given block once for each cell in the {Row}, passing that cell as parameter.
    # Each "cell" is just the calculated value for its column (pre-formatting) for this {Row}'s
    # source item.
    #
    # @example
    #   table = Tabulo::Table.new([1, 10], columns: %i(itself even?))
    #   row = table.first
    #   row.each do |cell|
    #     cell        # => 1,      => false
    #     cell.class  # => Fixnum, => FalseClass
    #   end
    def each
      @table.columns.each do |column|
        yield column.body_cell_value(@source)
      end
    end

    # @return a String being an "ASCII" graphical representation of the {Row}, including
    #   any column headers that appear just above it in the {Table} (depending on where this Row is
    #   in the {Table} and how the {Table} was configured with respect to header frequency).
    def to_s
      if @table.columns.any?
        @table.formatted_body_row(@source, with_header: @with_header)
      else
        ""
      end
    end

    # @return a Hash representation of the {Row}, with column labels acting
    #   as keys and the calculated cell values (before formatting) providing the values.
    #
    # @example
    #   table = Tabulo::Table.new([1, 10], columns: %i(itself even?))
    #   row = table.first
    #   row.to_h  # => { :itself => 1, :even? => false }
    #
    def to_h
      @table.columns.map(&:label).zip(to_a).to_h
    end
  end
end
