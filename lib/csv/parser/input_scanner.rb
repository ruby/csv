# frozen_string_literal: true

#
# CSV::InputsScanner receives IO inputs, encoding and the chunk_size.
# It also controls the life cycle of the object with its methods +keep_start+,
# +keep_end+, +keep_back+, +keep_drop+.
#
# CSV::InputsScanner.scan() tries to match with pattern at the current position.
# If there's a match, the scanner advances the "scan pointer" and returns the matched string.
# Otherwise, the scanner returns nil.
#
# CSV::InputsScanner.rest() returns the "rest" of the string (i.e. everything after the scan pointer).
# If there is no more data (eos? = true), it returns "".
#
class CSV
  class Parser
    class InputsScanner
      def initialize(inputs, encoding, row_separator, chunk_size: 8192)
        @inputs = inputs.dup
        @encoding = encoding
        @row_separator = row_separator
        @chunk_size = chunk_size
        @last_scanner = @inputs.empty?
        @keeps = []
        read_chunk
      end

      def each_line(row_separator)
        return enum_for(__method__, row_separator) unless block_given?
        buffer = nil
        input = @scanner.rest
        position = @scanner.pos
        offset = 0
        n_row_separator_chars = row_separator.size
        # trace(__method__, :start, line, input)
        while true
          input.each_line(row_separator) do |line|
            @scanner.pos += line.bytesize
            if buffer
              if n_row_separator_chars == 2 and
                  buffer.end_with?(row_separator[0]) and
                  line.start_with?(row_separator[1])
                buffer << line[0]
                line = line[1..-1]
                position += buffer.bytesize + offset
                @scanner.pos = position
                offset = 0
                yield(buffer)
                buffer = nil
                next if line.empty?
              else
                buffer << line
                line = buffer
                buffer = nil
              end
            end
            if line.end_with?(row_separator)
              position += line.bytesize + offset
              @scanner.pos = position
              offset = 0
              yield(line)
            else
              buffer = line
            end
          end
          break unless read_chunk
          input = @scanner.rest
          position = @scanner.pos
          offset = -buffer.bytesize if buffer
        end
        yield(buffer) if buffer
      end

      def scan(pattern)
        # trace(__method__, pattern, :start)
        value = @scanner.scan(pattern)
        # trace(__method__, pattern, :done, :last, value) if @last_scanner
        return value if @last_scanner

        read_chunk if value and @scanner.eos?
        # trace(__method__, pattern, :done, value)
        value
      end

      def scan_all(pattern)
        # trace(__method__, pattern, :start)
        value = @scanner.scan(pattern)
        # trace(__method__, pattern, :done, :last, value) if @last_scanner
        return value if @last_scanner

        return nil if value.nil?
        while @scanner.eos? and read_chunk and (sub_value = @scanner.scan(pattern))
          # trace(__method__, pattern, :sub, sub_value)
          value << sub_value
        end
        # trace(__method__, pattern, :done, value)
        value
      end

      def eos?
        @scanner.eos?
      end

      def keep_start
        # trace(__method__, :start)
        adjust_last_keep
        @keeps.push([@scanner, @scanner.pos, nil])
        # trace(__method__, :done)
      end

      def keep_end
        # trace(__method__, :start)
        scanner, start, buffer = @keeps.pop
        if scanner == @scanner
          keep = @scanner.string.byteslice(start, @scanner.pos - start)
        else
          keep = @scanner.string.byteslice(0, @scanner.pos)
        end
        if buffer
          buffer << keep
          keep = buffer
        end
        # trace(__method__, :done, keep)
        keep
      end

      def keep_back
        # trace(__method__, :start)
        scanner, start, buffer = @keeps.pop
        if buffer
          # trace(__method__, :rescan, start, buffer)
          string = @scanner.string
          if scanner == @scanner
            keep = string.byteslice(start, string.bytesize - start)
          else
            keep = string
          end
          if keep and not keep.empty?
            @inputs.unshift(StringIO.new(keep))
            @last_scanner = false
          end
          @scanner = StringScanner.new(buffer)
        else
          if @scanner != scanner
            message = "scanners are different but no buffer: "
            message += "#{@scanner.inspect}(#{@scanner.object_id}): "
            message += "#{scanner.inspect}(#{scanner.object_id})"
            raise UnexpectedError, message
          end
          # trace(__method__, :repos, start, buffer)
          @scanner.pos = start
        end
        read_chunk if @scanner.eos?
      end

      def keep_drop
        _, _, buffer = @keeps.pop
        # trace(__method__, :done, :empty) unless buffer
        return unless buffer

        last_keep = @keeps.last
        # trace(__method__, :done, :no_last_keep) unless last_keep
        return unless last_keep

        if last_keep[2]
          last_keep[2] << buffer
        else
          last_keep[2] = buffer
        end
        # trace(__method__, :done)
      end

      def rest
        @scanner.rest
      end

      def check(pattern)
        @scanner.check(pattern)
      end

      private
      def trace(*args)
        pp([*args, @scanner, @scanner&.string, @scanner&.pos, @keeps])
      end

      def adjust_last_keep
        # trace(__method__, :start)

        keep = @keeps.last
        # trace(__method__, :done, :empty) if keep.nil?
        return if keep.nil?

        scanner, start, buffer = keep
        string = @scanner.string
        if @scanner != scanner
          start = 0
        end
        if start == 0 and @scanner.eos?
          keep_data = string
        else
          keep_data = string.byteslice(start, @scanner.pos - start)
        end
        if keep_data
          if buffer
            buffer << keep_data
          else
            keep[2] = keep_data.dup
          end
        end

        # trace(__method__, :done)
      end

      def read_chunk
        return false if @last_scanner

        adjust_last_keep

        input = @inputs.first
        case input
        when StringIO
          string = input.read
          raise InvalidEncoding unless string.valid_encoding?
          # trace(__method__, :stringio, string)
          @scanner = StringScanner.new(string)
          @inputs.shift
          @last_scanner = @inputs.empty?
          true
        else
          chunk = input.gets(@row_separator, @chunk_size)
          if chunk
            raise InvalidEncoding unless chunk.valid_encoding?
            # trace(__method__, :chunk, chunk)
            @scanner = StringScanner.new(chunk)
            if input.respond_to?(:eof?) and input.eof?
              @inputs.shift
              @last_scanner = @inputs.empty?
            end
            true
          else
            # trace(__method__, :no_chunk)
            @scanner = StringScanner.new("".encode(@encoding))
            @inputs.shift
            @last_scanner = @inputs.empty?
            if @last_scanner
              false
            else
              read_chunk
            end
          end
        end
      end
    end
  end
end
