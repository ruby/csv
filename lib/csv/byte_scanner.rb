# frozen_string_literal: true

class CSV
  class Parser
    # The patterns CSV::Parser scans with, answered by comparing bytes in
    # Ruby instead of running a regular expression.
    #
    # Every pattern is built from ASCII separators, and the parser uses them
    # only on Strings in an encoding where an ASCII byte is always an ASCII
    # character (see Parser#byte_scannable?). So where a run of bytes stops
    # is where the equivalent regular expression's match stops.
    #
    # Every kind of pattern is an instance of this one class, with the same
    # instance variables, so the call sites that use them stay monomorphic
    # for YJIT. ByteScanner#skip and #scan answer the commonest kinds
    # themselves and call into the pattern only for the rest, because
    # without YJIT each Ruby method call is a large part of a scan.
    class BytePattern
      BYTEINDEX_AVAILABLE = "".respond_to?(:byteindex)

      # ByteScanner#scan reads these to answer the commonest kinds itself.
      attr_reader :kind
      attr_reader :bytes

      class << self
        # A String, as StringScanner#scan(String) matches it.
        def literal(literal)
          bytes = literal.bytes.freeze
          if bytes.size == 1
            new(:byte, bytes[0], nil)
          else
            new(:literal, bytes, nil)
          end
        end

        # Literals in alternation (/a|b|c/): the first that matches, in
        # order.
        def alternation(literals)
          new(:alternation,
              nil,
              literals.collect {|literal| literal.bytes.freeze}.freeze)
        end

        # One or more bytes not in a set (/[^...]+/).
        def run_except(characters)
          # An ASCII-only binary String is compatible with any
          # ASCII-compatible String, so byteindex searches the bytes.
          bytes = characters.bytes.uniq
          stops = Array.new(256, false)
          bytes.each {|byte| stops[byte] = true}
          items = bytes.collect {|byte| byte.chr.b.freeze}.freeze
          if items.size == 1
            new(:byte_until, items[0], nil)
          else
            new(:run_except, stops.freeze, items)
          end
        end

        # One or more bytes in a set (/[...]+/, /c+/).
        def run_in(characters)
          bytes = characters.bytes.uniq
          if bytes.size == 1
            new(:byte_run, bytes[0], nil)
          else
            members = Array.new(256, false)
            bytes.each {|byte| members[byte] = true}
            new(:run_in, members.freeze, nil)
          end
        end
      end

      def initialize(kind, bytes, items)
        @kind = kind
        @bytes = bytes
        @items = items
        @n_items = items ? items.size : 0
        @stops = items ? items.dup : nil
        @next = Array.new(@n_items, -1)
        @string = nil
        @string_size = -1
        @last_pos = 0
      end

      # The number of bytes the pattern matches at +pos+ in +string+, or nil.
      # Like the regular expressions it replaces, it matches nothing at the
      # end of the String: String#getbyte answers nil there.
      def match_length(string, pos)
        kind = @kind
        if kind == :byte
          match_byte(string, pos)
        elsif kind == :byte_run
          match_byte_run(string, pos)
        elsif kind == :byte_until
          match_byte_until(string, pos)
        elsif kind == :run_except
          run_except_length(string, pos)
        elsif kind == :run_in
          match_run_in(string, pos)
        elsif kind == :literal
          match_literal(string, pos)
        else
          match_alternation(string, pos)
        end
      end

      def run_except_length(string, pos)
        # Each stop byte is found with String#byteindex, a byte search with
        # no regular expression. The stops are kept in order of their next
        # position, so when the scan passes the nearest one, only that one
        # is searched again and moved back to its place, usually with one
        # comparison. A String is searched once per stop byte however many
        # values it has, and a stop byte that never appears costs one
        # search, not one per value. Kept positions hold only for the same
        # String and for positions that do not move back.
        size = string.bytesize
        positions = @next
        unless string.equal?(@string) and
               size == @string_size and
               pos >= @last_pos
          @string = string
          @string_size = size
          positions.fill(-1)
        end
        @last_pos = pos
        nearest = positions[0]
        if nearest < pos
          stops = @stops
          last = @n_items - 1
          while nearest < pos
            stop = stops[0]
            position = string.byteindex(stop, pos) || size
            i = 0
            while i < last and (next_position = positions[i + 1]) < position
              positions[i] = next_position
              stops[i] = stops[i + 1]
              i += 1
            end
            positions[i] = position
            stops[i] = stop
            nearest = positions[0]
          end
        end
        length = nearest - pos
        length > 0 ? length : nil
      end

      private

      def match_byte(string, pos)
        string.getbyte(pos) == @bytes ? 1 : nil
      end

      def match_byte_run(string, pos)
        byte = @bytes
        return nil unless string.getbyte(pos) == byte
        i = pos + 1
        i += 1 while string.getbyte(i) == byte
        i - pos
      end

      # With one stop byte the search ends where the match ends, so the
      # String is read once however many values it has.
      def match_byte_until(string, pos)
        stop = string.byteindex(@bytes, pos)
        length = (stop || string.bytesize) - pos
        length > 0 ? length : nil
      end

      def match_run_in(string, pos)
        members = @bytes
        i = pos
        while (byte = string.getbyte(i)) and members[byte]
          i += 1
        end
        length = i - pos
        length > 0 ? length : nil
      end

      def match_literal(string, pos)
        bytes = @bytes
        size = bytes.size
        return nil if size.zero?
        i = 0
        while i < size
          return nil unless string.getbyte(pos + i) == bytes[i]
          i += 1
        end
        size
      end

      def match_alternation(string, pos)
        j = 0
        while j < @n_items
          bytes = @items[j]
          size = bytes.size
          i = 0
          i += 1 while i < size and string.getbyte(pos + i) == bytes[i]
          return size if i == size
          j += 1
        end
        nil
      end
    end

    # The part of StringScanner that CSV::Parser uses, in Ruby. #scan and
    # #check take a BytePattern.
    class ByteScanner
      attr_reader :string
      attr_reader :pos

      def initialize(string)
        @string = string
        @pos = 0
      end

      def pos=(position)
        size = @string.bytesize
        position += size if position < 0
        raise RangeError, "index out of range" if position < 0 or position > size
        @pos = position
      end

      def skip(pattern)
        string = @string
        pos = @pos
        kind = pattern.kind
        if kind == :byte
          return nil unless string.getbyte(pos) == pattern.bytes
          length = 1
        elsif kind == :byte_run
          byte = pattern.bytes
          return nil unless string.getbyte(pos) == byte
          i = pos + 1
          i += 1 while string.getbyte(i) == byte
          length = i - pos
        elsif kind == :byte_until
          stop = string.byteindex(pattern.bytes, pos)
          length = (stop || string.bytesize) - pos
          return nil unless length > 0
        elsif kind == :run_except
          length = pattern.run_except_length(string, pos)
          return nil unless length
        else
          length = pattern.match_length(string, pos)
          return nil unless length
        end
        @pos = pos + length
        length
      end

      def scan(pattern)
        string = @string
        pos = @pos
        kind = pattern.kind
        if kind == :byte
          return nil unless string.getbyte(pos) == pattern.bytes
          length = 1
        elsif kind == :byte_run
          byte = pattern.bytes
          return nil unless string.getbyte(pos) == byte
          i = pos + 1
          i += 1 while string.getbyte(i) == byte
          length = i - pos
        elsif kind == :byte_until
          stop = string.byteindex(pattern.bytes, pos)
          length = (stop || string.bytesize) - pos
          return nil unless length > 0
        elsif kind == :run_except
          length = pattern.run_except_length(string, pos)
          return nil unless length
        else
          length = pattern.match_length(string, pos)
          return nil unless length
        end
        @pos = pos + length
        string.byteslice(pos, length)
      end

      def check(pattern)
        length = pattern.match_length(@string, @pos)
        length and @string.byteslice(@pos, length)
      end

      def eos?
        @pos >= @string.bytesize
      end

      def rest
        @string.byteslice(@pos, @string.bytesize - @pos)
      end

      def inspect
        "#<#{self.class} #{@pos}/#{@string.bytesize}>"
      end
    end
  end
end
