module Tabulo

  # @!visibility private
  def self.warn_deprecated(deprecated, replacement, stack_level = 1)
    warn "#{Kernel.caller[stack_level]}: [DEPRECATION] #{deprecated} is deprecated. Please use #{replacement} instead."
  end
end
