# frozen_string_literal: true

require "strscan"

require_relative "table"
require_relative "row"

class CSV
  class Parser
    class InvalidEncoding < StandardError
    end

    class Scanner < StringScanner
      alias_method :scan_all, :scan

      def initialize(*args)
        super
        @keep_start = nil
      end

      def keep_start
        @keep_start = pos
      end

      def keep_end
        string[@keep_start, pos - @keep_start]
      end
    end

    class InputsScanner
      def initialize(inputs, encoding, chunk_size: 8192)
        @inputs = inputs.dup
        @encoding = encoding
        @chunk_size = chunk_size
        @keep_start = nil
        read_chunk
      end

      def scan(pattern)
        value = @scanner.scan(pattern)
        if value
          read_chunk if @scanner.eos?
          return value
        else
          nil
        end
      end

      def scan_all(pattern)
        value = @scanner.scan(pattern)
        return nil if value.nil?
        while @scanner.eos? and read_chunk and (sub_value = @scanner.scan(pattern))
          value << sub_value
        end
        value
      end

      def eos?
        @scanner.eos?
      end

      def keep_start
        @keep_start = @scanner.pos
        @keep_buffer = nil
      end

      def keep_end
        keep = @scanner.string[@keep_start, @scanner.pos - @keep_start]
        start = @keep_start
        @keep_start = nil
        if @keep_buffer
          @keep_buffer << keep
          keep = @keep_buffer
          @keep_buffer = nil
        end
        keep
      end

      def rest
        @scanner.rest
      end

      def pos
        @scanner.pos
      end

      def pos=(new_pos)
        @scanner.pos = new_pos
        read_chunk if @scanner.eos?
        new_pos
      end

      private
      def read_chunk
        return false if @inputs.empty?

        if @keep_start
          string = @scanner.string
          keep = string[@keep_start, @scanner.pos - @keep_start]
          if keep
            if @keep_buffer
              @keep_buffer << keep
            else
              @keep_buffer = keep.dup
            end
          end
          @keep_start = 0
        end

        input = @inputs.first
        case input
        when StringIO
          string = input.string
          raise InvalidEncoding unless string.valid_encoding?
          @scanner = StringScanner.new(string)
          @inputs.shift
          true
        else
          chunk = input.gets(nil, @chunk_size)
          if chunk
            raise InvalidEncoding unless chunk.valid_encoding?
            @scanner = StringScanner.new(chunk)
            true
          else
            @scanner = StringScanner.new("".encode(@encoding))
            @inputs.shift
            read_chunk
          end
        end
      end
    end

    def initialize(input, options)
      @input = input
      @options = options
      @samples = []

      prepare
    end

    def column_separator
      @column_separator
    end

    def row_separator
      @row_separator
    end

    def quote_character
      @quote_character
    end

    def field_size_limit
      @field_size_limit
    end

    def skip_lines
      @skip_lines
    end

    def unconverted_fields?
      @unconverted_fields
    end

    def headers
      @headers
    end

    def header_row?
      @use_headers and @headers.nil?
    end

    def return_headers?
      @return_headers
    end

    def skip_blanks?
      @skip_blanks
    end

    def liberal_parsing?
      @liberal_parsing
    end

    def lineno
      @lineno
    end

    def line
      @line
    end

    def parse(&block)
      return to_enum(__method__) unless block_given?

      if @return_headers and @headers
        headers = Row.new(@headers, @raw_headers, true)
        if @unconverted_fields
          headers = add_unconverted_fields(headers, [])
        end
        yield headers
      end

      row = []
      begin
        scanner = build_scanner
        skip_needless_lines(scanner)
        scanner.keep_start
        while true
          @quoted_column_value = false
          @unquoted_column_value = false
          value = parse_column_value(scanner)
          if value and @field_size_limit and value.bytesize >= @field_size_limit
            raise MalformedCSVError.new("Field size exceeded", @lineno + 1)
          end
          if scanner.scan(@column_end)
            row << value
          elsif parse_row_end(scanner)
            if row.empty? and value.nil?
              emit_row(scanner, [], &block) unless @skip_blanks
            else
              row << value
              emit_row(scanner, row, &block)
              row = []
            end
            skip_needless_lines(scanner)
            scanner.keep_start
          elsif scanner.eos?
            return if row.empty? and value.nil?
            row << value
            emit_row(scanner, row, &block)
            return
          else
            if @quoted_column_value
              message = "Do not allow except col_sep_split_separator " +
                "after quoted fields"
              raise MalformedCSVError.new(message, @lineno + 1)
            elsif @unquoted_column_value and scanner.scan(@cr_or_lf)
              message = "Unquoted fields do not allow \\r or \\n"
              raise MalformedCSVError.new(message, @lineno + 1)
            elsif scanner.rest.start_with?(@quote_character)
              message = "Illegal quoting"
              raise MalformedCSVError.new(message, @lineno + 1)
            else
              raise MalformedCSVError.new("TODO: Meaningful message",
                                          @lineno + 1)
            end
          end
        end
      rescue InvalidEncoding
        message = "Invalid byte sequence in #{@encoding}"
        raise MalformedCSVError.new(message, @lineno + 1)
      end
    end

    private
    def prepare
      prepare_variable
      prepare_regexp
      prepare_line
      prepare_header
    end

    def prepare_variable
      @encoding = @options[:encoding]
      @liberal_parsing = @options[:liberal_parsing]
      @unconverted_fields = @options[:unconverted_fields]
      @field_size_limit = @options[:field_size_limit]
      @skip_blanks = @options[:skip_blanks]
      @fields_converter = @options[:fields_converter]
      @header_fields_converter = @options[:header_fields_converter]
    end

    def prepare_regexp
      @column_separator = @options[:col_sep].to_s.encode(@encoding)
      @row_separator = resolve_row_separator(@options[:row_sep]).encode(@encoding)
      @quote_character = @options[:quote_char].to_s.encode(@encoding)
      if @quote_character.length != 1
        raise ArgumentError, ":quote_char has to be a single character String"
      end

      escaped_col_sep = Regexp.escape(@column_separator)
      escaped_row_sep = Regexp.escape(@row_separator)
      escaped_quote_char = Regexp.escape(@quote_character)

      skip_lines = @options[:skip_lines]
      case skip_lines
      when String
        @skip_lines = Regexp.new("\\A[^".encode(@encoding) +
                                 escaped_row_sep +
                                 "]*".encode(@encoding) +
                                 Regexp.escape(skip_lines.encode(@encoding)) +
                                 "[^".encode(@encoding) +
                                 escaped_row_sep +
                                 "]*".encode(@encoding) +
                                 "(?:".encode(@encoding) +
                                 escaped_row_sep +
                                 ")?".encode(@encoding))
      when Regexp
        @skip_lines = Regexp.new("\\A".encode(@encoding) +
                                 skip_lines.to_s +
                                 "[^".encode(@encoding) +
                                 escaped_row_sep +
                                 "]*".encode(@encoding) +
                                 "(?:".encode(@encoding) +
                                 escaped_row_sep +
                                 ")?".encode(@encoding))
      when nil
        @skip_lines = nil
      else
        unless skip_lines.respond_to?(:match)
          message =
            ":skip_lines has to respond to \#match: #{skip_lines.inspect}"
          raise ArgumentError, message
        end
        @skip_lines = skip_lines
      end

      @column_end = Regexp.new(escaped_col_sep)
      @row_end = Regexp.new(escaped_row_sep)
      if @row_separator.size > 1
        @row_ends = @row_separator.each_char.collect do |char|
          Regexp.new(Regexp.escape(char))
        end
      else
        @row_ends = nil
      end
      @quoted_value = Regexp.new("[^".encode(@encoding) +
                                 escaped_quote_char +
                                 "]*".encode(@encoding) +
                                 escaped_quote_char)
      if @liberal_parsing
        @unquoted_value = Regexp.new("[^".encode(@encoding) +
                                     escaped_col_sep +
                                     "\r\n]+".encode(@encoding))
      else
        @unquoted_value = Regexp.new("[^".encode(@encoding) +
                                     escaped_quote_char +
                                     escaped_col_sep +
                                     "\r\n]+".encode(@encoding))
      end
      @quote = Regexp.new(escaped_quote_char)
      @cr_or_lf = Regexp.new("[\r\n]".encode(@encoding))
      @one_line = Regexp.new("\\A[^".encode(@encoding) +
                             escaped_row_sep +
                             "]*?".encode(@encoding) +
                             escaped_row_sep)
    end

    def resolve_row_separator(separator)
      if separator == :auto
        cr = "\r".encode(@encoding)
        lf = "\n".encode(@encoding)
        if @input.is_a?(StringIO)
          separator = detect_row_separator(@input.string, cr, lf)
        elsif @input.respond_to?(:gets)
          begin
            while separator == :auto
              #
              # if we run out of data, it's probably a single line
              # (ensure will set default value)
              #
              break unless sample = @input.gets(nil, 1024)

              # extend sample if we're unsure of the line ending
              if sample.end_with?(cr)
                sample << (@input.gets(nil, 1) || "")
              end

              @samples << sample

              separator = detect_row_separator(sample, cr, lf)
            end
          rescue IOError
            # do nothing:  ensure will set default
          end
        end
        separator = $INPUT_RECORD_SEPARATOR if separator == :auto
      end
      separator.to_s.encode(@encoding)
    end

    def detect_row_separator(sample, cr, lf)
      lf_index = sample.index(lf)
      if lf_index
        cr_index = sample[0, lf_index].index(cr)
      else
        cr_index = sample.index(cr)
      end
      if cr_index and lf_index
        if cr_index + 1 == lf_index
          cr + lf
        elsif cr_index < lf_index
          cr
        else
          lf
        end
      elsif cr_index
        cr
      elsif lf_index
        lf
      else
        :auto
      end
    end

    def prepare_line
      @lineno = 0
      @line = nil
    end

    def prepare_header
      @return_headers = @options[:return_headers]

      headers = @options[:headers]
      case headers
      when Array
        @raw_headers = headers
        @use_headers = true
      when String
        @raw_headers = parse_headers(headers)
        @use_headers = true
      when nil, false
        @raw_headers = nil
        @use_headers = false
      else
        @raw_headers = nil
        @use_headers = true
      end
      if @raw_headers
        @headers = adjust_headers(@raw_headers)
      else
        @headers = nil
      end
    end

    def parse_headers(row)
      CSV.parse_line(row,
                     col_sep:    @column_separator,
                     row_sep:    @row_separator,
                     quote_char: @quote_character)
    end

    def adjust_headers(headers)
      adjusted_headers = @header_fields_converter.convert(headers, nil, @lineno)
      adjusted_headers.each {|h| h.freeze if h.is_a? String}
      adjusted_headers
    end

    SCANNER_TEST = (ENV["CSV_PARSER_SCANNER_TEST"] == "yes")
    if SCANNER_TEST
      class UnoptimizedStringIO
        def initialize(string)
          @io = StringIO.new(string)
        end

        def gets(*args)
          @io.gets(*args)
        end
      end

      def build_scanner
        inputs = @samples.collect do |sample|
          UnoptimizedStringIO.new(sample)
        end
        inputs << @input
        InputsScanner.new(inputs, @encoding, chunk_size: 1)
      end
    else
      def build_scanner
        if @samples.empty? and @input.is_a?(StringIO)
          string = @input.string
          unless string.valid_encoding?
            message = "Invalid byte sequence in #{@encoding}"
            raise MalformedCSVError.new(message, @lineno + 1)
          end
          Scanner.new(string)
        else
          inputs = @samples.collect do |sample|
            StringIO.new(sample)
          end
          inputs << @input
          InputsScanner.new(inputs, @encoding)
        end
      end
    end

    def skip_needless_lines(scanner)
      case @skip_lines
      when nil
      when Regexp
        while scanner.scan_all(@skip_lines)
        end
      else
        while true
          pos = scanner.pos
          line = scanner.scan(@one_line)
          break unless line
          unless @skip_lines.match(line)
            scanner.pos = pos
            break
          end
        end
      end
    end

    def parse_column_value(scanner)
      if @liberal_parsing
        if scanner.scan(@quote)
          @quoted_column_value = true
          quoted_value = nil
          while true
            sub_quoted_value = scanner.scan(@quoted_value)
            unless sub_quoted_value
              message = "Unclosed quoted field"
              raise MalformedCSVError.new(message, @lineno + 1)
            end
            if quoted_value
              quoted_value << sub_quoted_value
            else
              quoted_value = sub_quoted_value
            end
            break unless scanner.scan(@quote)
          end

          unquoted_value = scanner.scan_all(@unquoted_value)
          if unquoted_value
            @quote_character + quoted_value + unquoted_value
          else
            quoted_value[0..-2]
          end
        else
          scanner.scan_all(@unquoted_value)
        end
      else
        value = scanner.scan_all(@unquoted_value)
        if value
          @unquoted_column_value = true
          return value
        end
        if scanner.scan(@quote)
          @quoted_column_value = true
          value = nil
          while true
            quoted_value = scanner.scan(@quoted_value)
            unless quoted_value
              message = "Unclosed quoted field"
              raise MalformedCSVError.new(message, @lineno + 1)
            end
            if value
              value << quoted_value
            else
              value = quoted_value
            end
            break unless scanner.scan(@quote)
          end
          value[0..-2]
        else
          nil
        end
      end
    end

    def parse_row_end(scanner)
      scanner.scan(@row_end) or
        (@row_ends and @row_ends.all? {|row_end| scanner.scan(row_end)})
    end

    def emit_row(scanner, row, &block)
      @lineno += 1
      @line = scanner.keep_end

      raw_row = row
      if @use_headers
        if @headers.nil?
          @headers = adjust_headers(row)
          return unless @return_headers
          row = Row.new(@headers, row, true)
        else
          row = Row.new(@headers,
                        @fields_converter.convert(raw_row, @headers, @lineno))
        end
      else
        # convert fields, if needed...
        row = @fields_converter.convert(raw_row, nil, @lineno)
      end

      # inject unconverted fields and accessor, if requested...
      if @unconverted_fields and not row.respond_to?(:unconverted_fields)
        add_unconverted_fields(row, raw_row)
      end

      yield(row)
    end

    # This method injects an instance variable <tt>unconverted_fields</tt> into
    # +row+ and an accessor method for +row+ called unconverted_fields().  The
    # variable is set to the contents of +fields+.
    def add_unconverted_fields(row, fields)
      class << row
        attr_reader :unconverted_fields
      end
      row.instance_variable_set(:@unconverted_fields, fields)
      row
    end
  end
end
