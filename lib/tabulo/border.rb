module Tabulo

  # @!visibility private
  class Border

    STYLES = {
      ascii: {
        corner_top_left: "+",
        corner_top_right: "+",
        corner_bottom_right: "+",
        corner_bottom_left: "+",
        edge_top: "-",
        edge_right: "|",
        edge_bottom: "-",
        edge_left: "|",
        tee_top: "+",
        tee_right: "+",
        tee_bottom: "+",
        tee_left: "+",
        divider_vertical: "|",
        divider_horizontal: "-",
        intersection: "+",
      },
      classic: {
        corner_top_left: "+",
        corner_top_right: "+",
        edge_top: "-",
        edge_right: "|",
        edge_left: "|",
        tee_top: "+",
        tee_right: "+",
        tee_left: "+",
        divider_vertical: "|",
        divider_horizontal: "-",
        intersection: "+",
      },
      reduced_ascii: {
        corner_top_left: "",
        corner_top_right: "",
        corner_bottom_right: "",
        corner_bottom_left: "",
        edge_top: "-",
        edge_right: "",
        edge_bottom: "-",
        edge_left: "",
        tee_top: " ",
        tee_right: "",
        tee_bottom: " ",
        tee_left: "",
        divider_vertical: " ",
        divider_horizontal: "-",
        intersection: " ",
      },
      markdown: {
        corner_top_left: "",
        corner_top_right: "",
        corner_bottom_right: "",
        corner_bottom_left: "",
        edge_top: "",
        edge_right: "|",
        edge_bottom: "",
        edge_left: "|",
        tee_top: "",
        tee_right: "|",
        tee_bottom: "",
        tee_left: "|",
        divider_vertical: "|",
        divider_horizontal: "-",
        intersection: "|",
      },
      modern: {
        corner_top_left: "┌",
        corner_top_right: "┐",
        corner_bottom_right: "┘",
        corner_bottom_left: "└",
        edge_top: "─",
        edge_right: "│",
        edge_bottom: "─",
        edge_left: "│",
        tee_top: "┬",
        tee_right: "┤",
        tee_bottom: "┴",
        tee_left: "├",
        divider_vertical: "│",
        divider_horizontal: "─",
        intersection: "┼",
      },
      blank: {
      },
    }

    # @!visibility private
    def self.from(initializer, styler = nil)
      new(options(initializer).merge(styler: styler))
    end

    # @!visibility private
    def horizontal_rule(column_widths, position = :bottom)
      left, center, right, segment =
        case position
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

    # @!visibility private
    def join_cell_contents(cells)
      styled_divider_vertical = style(@divider_vertical)
      styled_edge_left = style(@edge_left)
      styled_edge_right = style(@edge_right)
      styled_edge_left + cells.join(styled_divider_vertical) + styled_edge_right
    end

    private

    def self.options(kind)
      opts = STYLES[kind]
      return opts if opts
      raise InvalidBorderError
    end

    # @param [nil, #to_proc] styler (nil) A lambda or other callable object taking
    #   a single parameter, representing a section of the table's borders (which for this purpose
    #   include any horizontal and vertical lines inside the table), and returning a string.
    #   If passed <tt>nil</tt>, then no additional styling will be applied to borders. If passed a
    #   callable, then that callable will be called for each border section, with the
    #   resulting string rendered in place of that border. The extra width of the string returned by the
    #   {styler} is not taken into consideration by the internal table rendering calculations
    #   Thus it can be used to apply ANSI escape codes to border characters, to colour the borders
    #   for example, without breaking the table formatting.
    # @return [Border] a new {Border}
    def initialize(
      corner_top_left: "",
      corner_top_right: "",
      corner_bottom_right: "",
      corner_bottom_left: "",
      edge_top: "",
      edge_right: "",
      edge_bottom: "",
      edge_left: "",
      tee_top: "",
      tee_right: "",
      tee_bottom: "",
      tee_left: "",
      divider_vertical: "",
      divider_horizontal: "",
      intersection: "",
      styler: nil)

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

      @styler = styler
    end

    def style(s)
      @styler ? @styler.call(s) : s
    end
  end
end
