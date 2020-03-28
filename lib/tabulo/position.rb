module Tabulo

  # Represents the position of a {Cell} within a {Table}.
  #
  # @attr row [Integer] The positional index of the {Cell}'s {Row}. The topmost {Row} of the
  #   {Table} has index 0, the next has index 1, etc..
  # @attr column [Integer] The positional index of the {Cell}'s {Column}. The leftmost {Column}
  #   of the {Table} has index 0, the next has index 1, etc..
  Position = Struct.new(:row, :column)

end
