module Tabulo

  # Error indicating that the label of a column is invalid.
  class InvalidColumnLabelError < StandardError; end

  # Error indidication that an attempt was made to use an invalid horizontal rule character
  # for the table.
  class InvalidHorizontalRuleCharacterError < StandardError; end
end
