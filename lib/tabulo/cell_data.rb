module Tabulo

  # Contains information about a particular {Cell} in the {Table}.
  #
  # @attr source [Object] The member of this {Cell}'s {Table}'s underlying enumerable from which
  #   this {Cell}'s {Row} was derived.
  # @attr position [Position] The position of the {Cell} within the {Table}.
  CellData = Struct.new(:source, :position)

end
