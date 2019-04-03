module Tabulo

  # @!visibility private
  def self.warn_deprecated(deprecated, replacement, stack_level = 1)
    kaller = Kernel.caller[stack_level]
    Kernel.warn "#{kaller}: [DEPRECATION] #{deprecated} is deprecated. Please use #{replacement} instead."
  end
end
