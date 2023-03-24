# frozen_string_literal: true

require "strscan"

#
# CSV::Scanner receives a CSV output, scans it and return the content.
# It also controls the life cycle of the object with its methods +keep_start+,
# +keep_end+, +keep_back+, +keep_drop+.
#
# Uses StringScanner (the official strscan gem). Strscan provides lexical
# scanning operations on a String. We inherit its object and take advantage
# on the methods. For more information, please visit:
# https://ruby-doc.org/stdlib-2.6.1/libdoc/strscan/rdoc/StringScanner.html
#
class CSV
  class Parser
    class Scanner < StringScanner
      alias_method :scan_all, :scan

      def initialize(*args)
        super
        @keeps = []
      end

      def each_line(row_separator)
        position = pos
        rest.each_line(row_separator) do |line|
          position += line.bytesize
          self.pos = position
          yield(line)
        end
      end

      def keep_start
        @keeps.push(pos)
      end

      def keep_end
        start = @keeps.pop
        string.byteslice(start, pos - start)
      end

      def keep_back
        self.pos = @keeps.pop
      end

      def keep_drop
        @keeps.pop
      end
    end
  end
end
