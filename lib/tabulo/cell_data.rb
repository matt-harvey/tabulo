module Tabulo

  # Contains information about a particular {Cell} in the {Table}.
  #
  # @attr source [Object] The member of this {Cell}'s {Table}'s underlying enumerable from which
  #   this {Cell}'s {Row} was derived.
  # @attr row_index [Integer] The positional index of the {Cell}'s {Row}. The topmost {Row} of the
  #   {Table} has index 0, the next has index 1, etc.. The header row(s) are not counted for the purpose
  #   of this numbering.
  # @attr column_index [Integer] The positional index of the {Cell}'s {Column}. The leftmost {Column}
  #   of the {Table} has index 0, the next has index 1, etc..
  CellData = Struct.new(:source, :row_index, :column_index)

end
