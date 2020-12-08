module Tabulo

  # @!visibility private
  module Util

    NEWLINE = /\r\n|\n|\r/

    # @!visibility private
    def self.condense_lines(lines)
      join_lines(lines.reject(&:empty?))
    end

    # @!visibility private
    def self.divides?(smaller, larger)
      larger % smaller == 0
    end

    # @!visibility private
    def self.join_lines(lines)
      lines.join($/)
    end

    # @!visibility private
    def self.max(x, y)
      x > y ? x : y
    end

    # @!visibility private
    def self.slice_hash(hash, *keys)
      new_hash = {}
      keys.each { |k| new_hash[k] = hash[k] if hash.include?(k) }
      new_hash
    end

    # @!visibility private
    # @return [Integer] the length of the longest segment of str when split by newlines
    def self.wrapped_width(str)
      return 0 if str.empty?
      segments = str.split(NEWLINE)
      segments.inject(1) do |longest_length_so_far, segment|
        Util.max(longest_length_so_far, Unicode::DisplayWidth.of(segment))
      end
    end

  end
end

