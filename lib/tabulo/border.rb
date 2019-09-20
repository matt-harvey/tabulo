module Tabulo

  # FIXME Specs

  # @!visibility private
  class Border

    def initialize(
      corner_top_left:,
      corner_top_right:,
      corner_bottom_right:,
      corner_bottom_left:,
      edge_top:,
      edge_right:,
      edge_bottom:,
      edge_left:,
      tee_top:,
      tee_right:,
      tee_bottom:,
      tee_left:,
      divider_vertical:,
      divider_horizontal:,
      intersection:,
      styler:)

      @corner_top_left = corner_top_left
      @corner_top_right = corner_top_right
      @corner_bottom_right = corner_bottom_right
      @corner_bottom_left = corner_bottom_left

      @edge_top = edge_top
      @edge_right = edge_right
      @edge_bottom = edge_bottom
      @edge_left = edge_left

      @tee_top = tee_top
      @tee_right = tee_right
      @tee_bottom = tee_bottom
      @tee_left = tee_left

      @divider_vertical = divider_vertical
      @divider_horizontal = divider_horizontal

      @intersection = intersection

      @styler = (styler || -> (s) { s })
    end

    def self.classic(styler: nil)
      from_classic_options(
        horizontal_rule_character: Table::DEFAULT_HORIZONTAL_RULE_CHARACTER,
        vertical_rule_character: Table::DEFAULT_VERTICAL_RULE_CHARACTER,
        intersection_character: Table::DEFAULT_INTERSECTION_CHARACTER,
        styler: styler)
    end

    def self.modern(styler: nil)
      new(
      corner_top_left: '┌',
      corner_top_right: '┐',
      corner_bottom_right: '┘',
      corner_bottom_left: '└',
      edge_top: '─',
      edge_right: '│',
      edge_bottom: '─',
      edge_left: '│',
      tee_top: '┬',
      tee_right: '┤',
      tee_bottom: '┴',
      tee_left: '├',
      divider_vertical: '│',
      divider_horizontal: '─',
      intersection: '┼',
      styler: styler)
    end

    def self.from_classic_options(
      horizontal_rule_character:,
      vertical_rule_character:,
      intersection_character:,
      styler:)

      new(
        corner_top_left: intersection_character,
        corner_top_right: intersection_character,
        corner_bottom_right: intersection_character,
        corner_bottom_left: intersection_character,
        edge_top: horizontal_rule_character,
        edge_right: vertical_rule_character,
        edge_bottom: horizontal_rule_character,
        edge_left: vertical_rule_character,
        tee_top: intersection_character,
        tee_right: intersection_character,
        tee_bottom: intersection_character,
        tee_left: intersection_character,
        divider_vertical: vertical_rule_character,
        divider_horizontal: horizontal_rule_character,
        intersection: intersection_character,
        styler: styler)
    end

    def horizontal_rule(column_widths, placement = :middle)
      left, center, right, segment =
        case placement
        when :top
          [@corner_top_left, @tee_top, @corner_top_right, @edge_top]
        when :middle
          [@tee_left, @intersection, @tee_right, @divider_horizontal]
        when :bottom
          [@corner_bottom_left, @tee_bottom, @corner_bottom_right, @edge_bottom]
        end
      segments = column_widths.map { |width| segment * width }
      style("#{left}#{segments.join(center)}#{right}")
    end

    def join_cell_contents(cells)
      styled_divider_vertical = style(@divider_vertical)
      styled_edge_left = style(@edge_left)
      styled_edge_right = style(@edge_right)

      styled_edge_left + cells.join(styled_divider_vertical) + styled_edge_right
    end

    private

    def style(s)
      @styler.call(s)
    end
  end
end
