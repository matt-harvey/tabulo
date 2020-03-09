module Tabulo

  # @!visibility private
  module Util

    # @!visibility private
    def self.divides?(smaller, larger)
      larger % smaller == 0
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

  end
end

