module Tabulo

  # @!visibility private
  class Border

    Style = Struct.new(
        :corner_top_left, :corner_top_right, :corner_bottom_right, :corner_bottom_left,
        :edge_top, :edge_right, :edge_bottom, :edge_left,
        :tee_top, :tee_right, :tee_bottom, :tee_left,
        :divider_vertical, :divider_horizontal, :intersection)

    STYLES = {
      ascii:
        Style.new(
          "+", "+", "+", "+",
          "-", "|", "-", "|",
          "+", "+", "+", "+",
          "|", "-", "+",
        ),
      classic:
        Style.new(
          "+", "+", "", "",
          "-", "|", "", "|",
          "+", "+", "", "+",
          "|", "-", "+",
        ),
      reduced_ascii:
        Style.new(
          "", "", "", "",
          "-", "", "-", "",
          " ", "", " ", "",
          " ", "-", " ",
        ),
      reduced_modern:
        Style.new(
          "", "", "", "",
          "─", "", "─", "",
          " ", "", " ", "",
          " ", "─", " ",
        ),
      markdown:
        Style.new(
          "", "", "", "",
          "", "|", "", "|",
          "", "|", "", "|",
          "|", "-", "|",
        ),
      modern:
        Style.new(
          "┌", "┐", "┘", "└",
          "─", "│", "─", "│",
          "┬", "┤", "┴", "├",
          "│", "─", "┼",
        ),
      blank:
        Style.new(
          "", "", "", "",
          "", "", "", "",
          "", "", "", "",
          "", "", "",
        ),
    }

    # @!visibility private
    def self.from(initializer, styler = nil)
      new(**options(initializer).merge(styler: styler))
    end

    # @!visibility private
    def horizontal_rule(column_widths, position = :bottom)
      left, center, right, segment =
        case position
        when :title_top
          [@corner_top_left, @edge_top, @corner_top_right, @edge_top]
        when :title_bottom
          [@tee_left, @tee_top, @tee_right, @edge_top]
        when :top
          [@corner_top_left, @tee_top, @corner_top_right, @edge_top]
        when :middle
          [@tee_left, @intersection, @tee_right, @divider_horizontal]
        when :bottom
          [@corner_bottom_left, @tee_bottom, @corner_bottom_right, @edge_bottom]
        end
      segments = column_widths.map { |width| segment * width }

      # Prevent weird bottom edge of title if segments empty but right/left not empty, as in
      # Markdown border.
      left = right = "" if segments.all?(&:empty?)

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
      return opts.to_h if opts
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
      (@styler && !s.empty?) ? @styler.call(s) : s
    end
  end
end
