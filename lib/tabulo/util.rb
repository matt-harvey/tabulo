module Tabulo

  # @!visibility private
  module Util

    # @!visibility private
    def self.slice_hash(hash, *keys)
      new_hash = {}
      keys.each { |k| new_hash[k] = hash[k] if hash.include?(k) }
      new_hash
    end

  end
end

