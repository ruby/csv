require "English"
require "stringio"

class CSV
  module InputRecordSeparator
    class << self
      is_input_record_separator_deprecated = false
      if defined?(::Warning) # Warning was introduced in 2.4, $INPUT_RECORD_SEPARATOR was deprecated in 3.0
        original_method = ::Warning.singleton_class.instance_method(:warn)
        ::Warning.singleton_class.alias_method(:warn, :warn)
        begin
          ::Warning.singleton_class.define_method(:warn) do |message, *args, **kwargs|
            if message.include?("`$INPUT_RECORD_SEPARATOR' is deprecated")
              is_input_record_separator_deprecated = true
            else
              # If somehow we caught an unexpected warning, we call back the original method.
              original_method.bind(self).call(message, *args, **kwargs)
            end
          end
          $INPUT_RECORD_SEPARATOR = $INPUT_RECORD_SEPARATOR # trigger the deprecation warning
        ensure
          ::Warning.singleton_class.alias_method(:warn, :warn)
          ::Warning.singleton_class.define_method(:warn, original_method)
        end
      end

      if is_input_record_separator_deprecated
        def value
          "\n"
        end
      else
        def value
          $INPUT_RECORD_SEPARATOR
        end
      end
    end
  end
end
