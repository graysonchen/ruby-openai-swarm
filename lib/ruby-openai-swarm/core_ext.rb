# Backport of Array.wrap for Ruby versions prior to 3.0
# This provides a consistent way to wrap objects as arrays across different Ruby versions
# link: https://github.com/rails/rails/blob/main/activesupport/lib/active_support/core_ext/array/wrap.rb
unless Array.respond_to?(:wrap)
  class Array
    def self.wrap(object)
      if object.nil?
        []
      elsif object.respond_to?(:to_ary)
        object.to_ary || [object]
      else
        [object]
      end
    end
  end
end
