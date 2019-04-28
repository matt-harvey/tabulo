module Tabulo

  # @!visibility private
  module Deprecation

    # @!visibility private
    def self.skipping_warnings
      @skipping_warnings ||= false
    end

    # @!visibility private
    def self.skipping_warnings=(v)
      @skipping_warnings = v
    end

    # @!visibility private
    def self.without_warnings
      original = skipping_warnings
      self.skipping_warnings = true
      yield
    ensure
      self.skipping_warnings = original
    end

    # @!visibility private
    def self.warn(deprecated, replacement, stack_level = 1)
      return if skipping_warnings

      kaller = Kernel.caller[stack_level]
      Kernel.warn "#{kaller}: [DEPRECATION] #{deprecated} is deprecated. Please use #{replacement} instead."
    end
  end
end
