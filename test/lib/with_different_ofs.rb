# frozen_string_literal: false

module DifferentOFS
  is_output_field_separator_deprecated = false
  stderr, $stderr = $stderr, StringIO.new
  begin
    ofs, $, = $,, "-"
    is_output_field_separator_deprecated = (not $stderr.string.empty?)
  ensure
    $, = ofs
    $stderr = stderr
  end

  unless is_output_field_separator_deprecated
    module WithDifferentOFS
      def setup
        super
        @ofs, $, = $,, "-"
      end
      def teardown
        $, = @ofs
        super
      end
    end

    def self.extended(klass)
      super(klass)
      klass.const_set(:DifferentOFS, Class.new(klass).class_eval {include WithDifferentOFS}).name
    end
  end
end
