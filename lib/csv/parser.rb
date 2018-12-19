# frozen_string_literal: true

require "strscan"

require_relative "table"
require_relative "row"

class CSV
  class Parser
    def initialize(input, options)
      @input = input
      @options = options
      @prefix_input = nil

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

    def shift
      #########################################################################
      ### This method is purposefully kept a bit long as simple conditional ###
      ### checks are faster than numerous (expensive) method calls.         ###
      #########################################################################

      # handle headers not based on document content
      if @need_to_return_passed_headers
        @need_to_return_passed_headers = false
        headers = Row.new(@headers, @raw_headers, true)
        if @unconverted_fields
          headers = add_unconverted_fields(headers, [])
        end
        return headers
      end

      #
      # it can take multiple calls to <tt>@io.gets()</tt> to get a full line,
      # because of \r and/or \n characters embedded in quoted fields
      #
      in_extended_col = false
      csv             = []

      loop do
        # add another read to the line
        if @prefix_input
          parse = @prefix_input.gets(@row_separator)
          if @prefix_input.eof?
            unless parse.end_with?(@row_separator)
              parse << (@input.gets(@row_separator) || "")
            end
            @prefix_input = nil  # avoid having to test @prefix_input.eof? in main code path
          end
        else
          parse = @input.gets(@row_separator)
          return nil unless parse
        end

        if in_extended_col
          @line.concat(parse)
        else
          @line = parse.clone
        end

        begin
          parse.sub!(@line_end, "")
        rescue ArgumentError
          unless parse.valid_encoding?
            message = "Invalid byte sequence in #{parse.encoding}"
            raise MalformedCSVError.new(message, @lineno + 1)
          end
          raise
        end

        if csv.empty?
          #
          # I believe a blank line should be an <tt>Array.new</tt>, not Ruby 1.8
          # CSV's <tt>[nil]</tt>
          #
          if parse.empty?
            @lineno += 1
            if @skip_blanks
              next
            elsif @unconverted_fields
              return add_unconverted_fields([], [])
            elsif @use_headers
              return Row.new(@headers, [])
            else
              return []
            end
          end
        end

        next if @skip_lines and @skip_lines.match(parse)

        scanner = StringScanner.new(parse)
        if scanner.eos?
          if in_extended_col
            csv[-1] << @row_separator
          else
            csv << nil
          end
        end

        # This loop is the hot path of csv parsing. Some things may be non-dry
        # for a reason. Make sure to benchmark when refactoring.
        liberal_parsing_string = ""
        until scanner.eos?
          if in_extended_col
            if scanner.scan(@quote)
              if scanner.scan(@quote)
                csv.last << @quote_character
                next
              end
              in_extended_col = false
              if scanner.scan(@column_end)
                csv << liberal_parsing_string if @liberal_parsing
                if scanner.eos?
                  # e.g. %Q{a,"""\nb\n""",\nc}
                  csv << nil
                  break
                end
              elsif @liberal_parsing
                csv << +"#{@quote_character}#{liberal_parsing_string}#{@quote_character}"
                # e.g. '1,"\"2\"",3' #=> ["'1", "\"\\\"2\\\"\"", "3'"]
                csv.last << scanner.scan(@unquoted_value_liberal_parsing)
                next if scanner.eos? || scanner.scan(@column_end)
                message = "Do not allow except col_sep_split_separator after quoted fields"
                raise MalformedCSVError.new(message, @lineno + 1)
              elsif scanner.eos?
                break
              else
                # '"aaa,bbb"ccc'
                message = "Do not allow except col_sep_split_separator after quoted fields"
                raise MalformedCSVError.new(message, @lineno + 1)
              end
            elsif v = scanner.scan(@value)
              csv.last << v
              csv.last << @row_separator if scanner.eos?
            end
          elsif v = scanner.scan(@unquoted_value)
            csv << v

            if scanner.scan(@column_end)
              # e.g. "a,b,"
              csv << nil if scanner.eos?
              next
            end

            if @liberal_parsing && !scanner.eos?
              csv.last << scanner.scan(@unquoted_value_liberal_parsing)
              csv << nil if scanner.scan(@column_end) && scanner.eos?
              next
            end

            if scanner.scan(@nl_or_lf)
              message = "Unquoted fields do not allow \\r or \\n"
              raise MalformedCSVError.new(message, @lineno + 1)
            end

            if scanner.scan(@quote)
              raise MalformedCSVError.new("Illegal quoting", @lineno + 1)
            end

            unless scanner.eos?
              message = "Do not allow except col_sep_split_separator after quoted fields"
              raise MalformedCSVError.new(message, @lineno + 1)
            end
          elsif scanner.scan(@quote)
            # If we are starting a new quoted column
            in_extended_col =  true

            if v = scanner.scan(@value)
              if @liberal_parsing
                liberal_parsing_string = v
                liberal_parsing_string << @row_separator if scanner.eos?
              else
                csv << v
                csv.last << @row_separator if scanner.eos?
              end
            elsif scanner.scan(@quote)
              if scanner.scan(@quote)
                csv << @quote_character.dup
                csv.last << @row_separator if scanner.eos?
                next
              end
              if scanner.eos? || scanner.scan(@column_end)
                # e.g. '"aaa",""'
                csv << "" # will be replaced with a empty_value
                in_extended_col = false
                next
              else
                message = "Do not allow except col_sep_split_separator after quoted fields"
                raise MalformedCSVError.new(message, @lineno + 1)
              end
            elsif scanner.eos?
              csv << @row_separator.dup
            else
              csv << ""
            end
          elsif scanner.scan(@column_end)
            csv << nil
            if scanner.eos?
              # e.g. "a,b,"
              csv << nil
            else
              next
            end
          end
        end

        if in_extended_col
          # if we're at eof?(), a quoted field wasn't closed...
          if @input.eof? and !@prefix_input
            raise MalformedCSVError.new("Unclosed quoted field",
                                        @lineno + 1)
          elsif @field_size_limit and csv.last.size >= @field_size_limit
            raise MalformedCSVError.new("Field size exceeded",
                                        @lineno + 1)
          end
          # otherwise, we need to loop and pull some more data to complete the row
        else
          @lineno += 1

          # save fields unconverted fields, if needed...
          unconverted = csv.dup if @unconverted_fields

          if @use_headers
            # parse out header rows and handle CSV::Row conversions...
            if @headers.nil?
              @headers = adjust_headers(csv)
              if @return_headers
                csv = Row.new(@headers, csv, true)
              else
                csv = []
                next
              end
            else
              csv = Row.new(@headers,
                            @fields_converter.convert(csv, @headers, @lineno))
            end
          else
            # convert fields, if needed...
            csv = @fields_converter.convert(csv, nil, @lineno)
          end

          # inject unconverted fields and accessor, if requested...
          if @unconverted_fields and not csv.respond_to? :unconverted_fields
            add_unconverted_fields(csv, unconverted)
          end

          # return the results
          break csv
        end
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
      skip_lines = @options[:skip_lines]
      case skip_lines
      when String
        @skip_lines = Regexp.new(Regexp.escape(skip_lines.encode(@encoding)))
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

      @column_separator = @options[:col_sep].to_s.encode(@encoding)
      @row_separator = resolve_row_separator(@options[:row_sep])
      @quote_character = @options[:quote_char].to_s.encode(@encoding)
      if @quote_character.length != 1
        raise ArgumentError, ":quote_char has to be a single character String"
      end

      escaped_col_sep = Regexp.escape(@column_separator)
      escaped_row_sep = Regexp.escape(@row_separator)
      escaped_quote_char = Regexp.escape(@quote_character)
      @column_end = Regexp.new(escaped_col_sep)
      @value = Regexp.new("[^".encode(@encoding) +
                          escaped_quote_char +
                          "]+".encode(@encoding))
      @unquoted_value = Regexp.new("[^".encode(@encoding) +
                                   escaped_quote_char +
                                   escaped_col_sep +
                                   "\r\n]+".encode(@encoding))
      @unquoted_value_liberal_parsing =
        Regexp.new("[^".encode(@encoding) +
                   escaped_col_sep +
                   "\r\n]+".encode(@encoding))
      @quote = Regexp.new("[".encode(@encoding) +
                          escaped_quote_char +
                          "]".encode(@encoding))
      @nl_or_lf = Regexp.new("[\r\n]".encode(@encoding))
      @line_end = Regexp.new(escaped_row_sep +
                             "\\z".encode(@encoding))
    end

    def resolve_row_separator(separator)
      if separator == :auto
        saved_prefix = []  # sample chunks to be reprocessed later
        begin
          while separator == :auto && @input.respond_to?(:gets)
            #
            # if we run out of data, it's probably a single line
            # (ensure will set default value)
            #
            break unless sample = @input.gets(nil, 1024)

            cr = "\r".encode(@encoding)
            lf = "\n".encode(@encoding)
            # extend sample if we're unsure of the line ending
            if sample.end_with?(cr)
              sample << (@input.gets(nil, 1) || "")
            end

            saved_prefix << sample

            # try to find a standard separator
            last_char = nil
            sample.each_char.each_cons(2) do |char, next_char|
              last_char = next_char
              case char
              when cr
                if next_char == lf
                  separator = "\r\n".encode(@encoding)
                else
                  separator = cr
                end
                break
              when lf
                separator = lf
                break
              end
            end
            if separator == :auto
              case last_char
              when cr
                separator = cr
              when lf
                separator = lf
              end
            end
          end
        rescue IOError
          # do nothing:  ensure will set default
        ensure
          #
          # set default if we failed to detect
          # (stream not opened for reading or a single line of data)
          #
          separator = $INPUT_RECORD_SEPARATOR if separator == :auto

          # save sampled input for later parsing (but only if there is some!)
          saved_prefix = saved_prefix.join('')
          @prefix_input = StringIO.new(saved_prefix) unless saved_prefix.empty?
        end
      end
      separator.to_s.encode(@encoding)
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
        @need_to_return_passed_headers = @return_headers
      else
        @headers = nil
        @need_to_return_passed_headers = false
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
