module Tabulo

  # Error indicating that the label of a column is invalid.
  class InvalidColumnLabelError < StandardError; end

  # Error indicating that an attempt was made to use an invalid horizontal rule character
  # for the table.
  class InvalidHorizontalRuleCharacterError < StandardError; end

  # Error indicating that an attempt was made to use an invalid vertical rule character
  # for the table.
  class InvalidVerticalRuleCharacterError < StandardError; end

  # Error indicating that an attempt was made to use an invalid intersection character for
  # the table.
  class InvalidIntersectionCharacterError < StandardError; end
end
