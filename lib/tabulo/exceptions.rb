module Tabulo

  # Error indicating that the label of a column is invalid.
  class InvalidColumnLabelError < StandardError; end

  # Error indicating that an attempt was made to use an invalid truncation indicator for
  # the table.
  class InvalidTruncationIndicatorError < StandardError; end

  # Error indicating the table border configuration is invalid.
  class InvalidBorderError < StandardError; end
end
