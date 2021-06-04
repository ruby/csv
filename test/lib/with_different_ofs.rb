# frozen_string_literal: true

module DifferentOFS
  is_output_field_separator_deprecated = false
  verbose, $VERBOSE = $VERBOSE, true
  stderr, $stderr = $stderr, StringIO.new
  begin
    ofs, $, = $,, "-"
    is_output_field_separator_deprecated = (not $stderr.string.empty?)
  ensure
    $, = ofs
    $stderr = stderr
    $VERBOSE = verbose
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
      klass.const_set(:DifferentOFS, Class.new(klass).class_eval {include WithDifferentOFS})
    end
  end
end
