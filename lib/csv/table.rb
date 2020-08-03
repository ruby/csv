# frozen_string_literal: true

require "forwardable"

class CSV
  # = \CSV::Table
  # A \CSV::Table instance is an object representing \CSV data.
  # (see {class CSV}[../CSV.html]).
  #
  # The instance may have:
  # - Rows:  each is a Table::Row object.
  # - Headers:  names for the columns.
  #
  # === Instance Methods
  #
  # \CSV::Table has three groups of instance methods:
  # - Its own internally defined instance methods.
  # - Methods included by module Enumerable.
  # - Methods delegated to class Array.:
  #   * Array#empty?
  #   * Array#length
  #   * Array#size
  #
  # == Creating a \CSV::Table Instance
  #
  # Commonly, a new \CSV::Table instance is created by parsing \CSV source
  # using headers:
  #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
  #   table = CSV.parse(source, headers: true)
  #   table.class # => CSV::Table
  #
  # You can also create an instance directly. See ::new.
  #
  # == Headers
  #
  # If a table has headers, the headers serve as labels for the columns of data.
  # Each header serves as the label for its column.
  #
  # The headers for a \CSV::Table object are stored as an \Array of Strings.
  #
  # Commonly, headers are defined in the first row of \CSV source:
  #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
  #   table = CSV.parse(source, headers: true)
  #   table.headers # => ["Name", "Value"]
  #
  # If no headers are defined, the \Array is empty:
  #   table = CSV::Table.new([])
  #   table.headers # => []
  #
  # == Access Modes
  #
  # \CSV::Table provides three modes for accessing table data:
  # - \Row mode.
  # - Column mode.
  # - Mixed mode (the default for a new table).
  #
  # The access mode for a\CSV::Table instance affects the behavior
  # of some of its instance methods:
  # - #[]
  # - #[]=
  # - #delete
  # - #delete_if
  # - #each
  # - #values_at
  #
  # === \Row Mode
  #
  # Set a table to row mode with method #by_row!:
  #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
  #   table = CSV.parse(source, headers: true)
  #   table.by_row! # => #<CSV::Table mode:row row_count:4>
  #
  # Specify a single row by an \Integer index:
  #   # Get a row.
  #   table[1] # => #<CSV::Row "Name":"bar" "Value":"1">
  #   # Set a row, then get it.
  #   table[1] = CSV::Row.new(['Name', 'Value'], ['bam', 3])
  #   table[1] # => #<CSV::Row "Name":"bam" "Value":3>
  #
  # Specify a sequence of rows by a \Range:
  #   # Get rows.
  #   table[1..2] # => [#<CSV::Row "Name":"bam" "Value":3>, #<CSV::Row "Name":"baz" "Value":"2">]
  #   # Set rows, then get them.
  #   table[1..2] = [
  #     CSV::Row.new(['Name', 'Value'], ['bat', 4]),
  #     CSV::Row.new(['Name', 'Value'], ['bad', 5]),
  #   ]
  #   table[1..2] # => [["Name", #<CSV::Row "Name":"bat" "Value":4>], ["Value", #<CSV::Row "Name":"bad" "Value":5>]]
  #
  # === Column Mode
  #
  # Set a table to column mode with method #by_col!:
  #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
  #   table = CSV.parse(source, headers: true)
  #   table.by_col! # => #<CSV::Table mode:col row_count:4>
  #
  # Specify a column by an \Integer index:
  #   # Get a column.
  #   table[0]
  #   # Set a column, then get it.
  #   table[0] = ['FOO', 'BAR', 'BAZ']
  #   table[0] # => ["FOO", "BAR", "BAZ"]
  #
  # Specify a column by its \String header:
  #   # Get a column.
  #   table['Name'] # => ["FOO", "BAR", "BAZ"]
  #   # Set a column, then get it.
  #   table['Name'] = ['Foo', 'Bar', 'Baz']
  #   table['Name'] # => ["Foo", "Bar", "Baz"]
  #
  # === Mixed Mode
  #
  # In mixed mode, you can refer to either rows or columns:
  # - An \Integer index refers to a row.
  # - A \Range index refers to multiple rows.
  # - A \String index refers to a column.
  #
  # Set a table to mixed mode with method #by_col_or_row!:
  #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
  #   table = CSV.parse(source, headers: true)
  #   table.by_col_or_row! # => #<CSV::Table mode:col_or_row row_count:4>
  #
  # Specify a single row by an \Integer index:
  #   # Get a row.
  #   table[1] # => #<CSV::Row "Name":"bar" "Value":"1">
  #   # Set a row, then get it.
  #   table[1] = CSV::Row.new(['Name', 'Value'], ['bam', 3])
  #   table[1] # => #<CSV::Row "Name":"bam" "Value":3>
  #
  # Specify a sequence of rows by a \Range:
  #   # Get rows.
  #   table[1..2] # => [#<CSV::Row "Name":"bam" "Value":3>, #<CSV::Row "Name":"baz" "Value":"2">]
  #   # Set rows, then get them.
  #   table[1] = CSV::Row.new(['Name', 'Value'], ['bat', 4])
  #   table[2] = CSV::Row.new(['Name', 'Value'], ['bad', 5])
  #   table[1..2] # => [["Name", #<CSV::Row "Name":"bat" "Value":4>], ["Value", #<CSV::Row "Name":"bad" "Value":5>]]
  #
  # Specify a column by its \String header:
  #   # Get a column.
  #   table['Name'] # => ["foo", "bat", "bad"]
  #   # Set a column, then get it.
  #   table['Name'] = ['Foo', 'Bar', 'Baz']
  #   table['Name'] # => ["Foo", "Bar", "Baz"]
  class Table
    # :call-seq:
    #   CSV::Table.new(array_of_rows, headers = nil)
    #
    # Returns a new \CSV::Table object.
    #
    # - Argument +array_of_rows+ must be an \Array of CSV::Row objects.
    # - Argument +headers+, if given, may be an \Array of Strings.
    #
    # ---
    #
    # Create an empty \CSV::Table object:
    #   table = CSV::Table.new([])
    #   table # => #<CSV::Table mode:col_or_row row_count:1>
    #
    # Create a non-empty \CSV::Table object:
    #   rows = [
    #     CSV::Row.new([], []),
    #     CSV::Row.new([], []),
    #     CSV::Row.new([], []),
    #   ]
    #   table  = CSV::Table.new(rows)
    #   table # => #<CSV::Table mode:col_or_row row_count:4>
    #
    # ---
    #
    # If argument +headers+ is an \Array of Strings,
    # those Strings become the table's headers:
    #   table = CSV::Table.new([], headers: ['Name', 'Age'])
    #   table.headers # => ["Name", "Age"]
    #
    # If argument +headers+ is not given and the table has rows,
    # the headers are taken from the first row:
    #   rows = [
    #     CSV::Row.new(['Foo', 'Bar'], []),
    #     CSV::Row.new(['foo', 'bar'], []),
    #     CSV::Row.new(['FOO', 'BAR'], []),
    #   ]
    #   table  = CSV::Table.new(rows)
    #   table.headers # => ["Foo", "Bar"]
    #
    # If argument +headers+ is not given and the table is empty (has no rows),
    # the headers are also empty:
    #   table  = CSV::Table.new([])
    #   table.headers # => []
    #
    # ---
    #
    # Raises an exception if argument +array_of_rows+ is not an \Array object:
    #   # Raises NoMethodError (undefined method `first' for :foo:Symbol):
    #   CSV::Table.new(:foo)
    #
    # Raises an exception if an element of +array_of_rows+ is not a \CSV::Table object:
    #   # Raises NoMethodError (undefined method `headers' for :foo:Symbol):
    #   CSV::Table.new([:foo])
    def initialize(array_of_rows, headers: nil)
      @table = array_of_rows
      @headers = headers
      unless @headers
        if @table.empty?
          @headers = []
        else
          @headers = @table.first.headers
        end
      end

      @mode  = :col_or_row
    end

    # The current access mode for indexing and iteration.
    attr_reader :mode

    # Internal data format used to compare equality.
    attr_reader :table
    protected   :table

    ### Array Delegation ###

    extend Forwardable
    def_delegators :@table, :empty?, :length, :size

    # :call-seq:
    #   table.by_col
    #
    # Returns a duplicate of +self+, in column mode
    # (see {Column Mode}[#class-CSV::Table-label-Column+Mode]):
    #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
    #   table = CSV.parse(source, headers: true)
    #   table.mode # => :col_or_row
    #   dup_table = table.by_col
    #   dup_table.mode # => :col
    #   dup_table.equal?(table) # => false # It's a dup
    #
    # This may be used to chain method calls without changing the mode
    # (but also will affect performance and memory usage):
    #   dup_table.by_col['Name']
    #
    # Also note that changes to the duplicate table will not affect the original.
    def by_col
      self.class.new(@table.dup).by_col!
    end

    # :call-seq:
    #   table.by_col!
    #
    # Sets the mode for +self+ to column mode
    # (see {Column Mode}[#class-CSV::Table-label-Column+Mode]); returns +self+:
    #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
    #   table = CSV.parse(source, headers: true)
    #   table.mode # => :col_or_row
    #   table1 = table.by_col!
    #   table.mode # => :col
    #   table1.equal?(table) # => true # Returned self
    def by_col!
      @mode = :col

      self
    end

    # :call-seq:
    #   table.by_col_or_row
    #
    # Returns a duplicate of +self+, in mixed mode
    # (see {Mixed Mode}[#class-CSV::Table-label-Mixed+Mode]):
    #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
    #   table = CSV.parse(source, headers: true).by_col!
    #   table.mode # => :col
    #   dup_table = table.by_col_or_row
    #   dup_table.mode # => :col_or_row
    #   dup_table.equal?(table) # => false # It's a dup
    #
    # This may be used to chain method calls without changing the mode
    # (but also will affect performance and memory usage):
    #   dup_table.by_col_or_row['Name']
    #
    # Also note that changes to the duplicate table will not affect the original.
    def by_col_or_row
      self.class.new(@table.dup).by_col_or_row!
    end

    # :call-seq:
    #   table.by_col_or_row!
    #
    # Sets the mode for +self+ to mixed mode
    # (see {Mixed Mode}[#class-CSV::Table-label-Mixed+Mode]); returns +self+:
    #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
    #   table = CSV.parse(source, headers: true).by_col!
    #   table.mode # => :col
    #   table1 = table.by_col_or_row!
    #   table.mode # => :col_or_row
    #   table1.equal?(table) # => true # Returned self
    def by_col_or_row!
      @mode = :col_or_row

      self
    end

    # :call-seq:
    #   table.by_row
    #
    # Returns a duplicate of +self+, in row mode
    # (see {Row Mode}[#class-CSV::Table-label-Row+Mode]):
    #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
    #   table = CSV.parse(source, headers: true)
    #   table.mode # => :col_or_row
    #   dup_table = table.by_row
    #   dup_table.mode # => :row
    #   dup_table.equal?(table) # => false # It's a dup
    #
    # This may be used to chain method calls without changing the mode
    # (but also will affect performance and memory usage):
    #   dup_table.by_row[1]
    #
    # Also note that changes to the duplicate table will not affect the original.
    def by_row
      self.class.new(@table.dup).by_row!
    end

    # :call-seq:
    #   table.by_row!
    #
    # Sets the mode for +self+ to row mode
    # (see {Row Mode}[#class-CSV::Table-label-Row+Mode]); returns +self+:
    #   source = "Name,Value\nfoo,0\nbar,1\nbaz,2\n"
    #   table = CSV.parse(source, headers: true)
    #   table.mode # => :col_or_row
    #   table1 = table.by_row!
    #   table.mode # => :row
    #   table1.equal?(table) # => true # Returned self
    def by_row!
      @mode = :row

      self
    end

    # :call-seq:
    #   table.headers
    #
    # Returns a new \Array containing the \String headers for the table.
    #
    # If the table is not empty, returns the headers from the first row:
    #   rows = [
    #     CSV::Row.new(['Foo', 'Bar'], []),
    #     CSV::Row.new(['FOO', 'BAR'], []),
    #     CSV::Row.new(['foo', 'bar'], []),
    #   ]
    #   table  = CSV::Table.new(rows)
    #   table.headers # => ["Foo", "Bar"]
    #   table.delete(0)
    #   table.headers # => ["FOO", "BAR"]
    #   table.delete(0)
    #   table.headers # => ["foo", "bar"]
    #
    # If the table is empty, returns a copy of the headers in the table itself:
    #   table.delete(0)
    #   table.headers # => ["Foo", "Bar"]
    def headers
      if @table.empty?
        @headers.dup
      else
        @table.first.headers
      end
    end

    #
    # In the default mixed mode, this method returns rows for index access and
    # columns for header access. You can force the index association by first
    # calling by_col!() or by_row!().
    #
    # Columns are returned as an Array of values.  Altering that Array has no
    # effect on the table.
    #
    def [](index_or_header)
      if @mode == :row or  # by index
         (@mode == :col_or_row and (index_or_header.is_a?(Integer) or index_or_header.is_a?(Range)))
        @table[index_or_header]
      else                 # by header
        @table.map { |row| row[index_or_header] }
      end
    end

    #
    # In the default mixed mode, this method assigns rows for index access and
    # columns for header access. You can force the index association by first
    # calling by_col!() or by_row!().
    #
    # Rows may be set to an Array of values (which will inherit the table's
    # headers()) or a CSV::Row.
    #
    # Columns may be set to a single value, which is copied to each row of the
    # column, or an Array of values. Arrays of values are assigned to rows top
    # to bottom in row major order. Excess values are ignored and if the Array
    # does not have a value for each row the extra rows will receive a +nil+.
    #
    # Assigning to an existing column or row clobbers the data. Assigning to
    # new columns creates them at the right end of the table.
    #
    def []=(index_or_header, value)
      if @mode == :row or  # by index
         (@mode == :col_or_row and index_or_header.is_a? Integer)
        if value.is_a? Array
          @table[index_or_header] = Row.new(headers, value)
        else
          @table[index_or_header] = value
        end
      else                 # set column
        unless index_or_header.is_a? Integer
          index = @headers.index(index_or_header) || @headers.size
          @headers[index] = index_or_header
        end
        if value.is_a? Array  # multiple values
          @table.each_with_index do |row, i|
            if row.header_row?
              row[index_or_header] = index_or_header
            else
              row[index_or_header] = value[i]
            end
          end
        else                  # repeated value
          @table.each do |row|
            if row.header_row?
              row[index_or_header] = index_or_header
            else
              row[index_or_header] = value
            end
          end
        end
      end
    end

    #
    # The mixed mode default is to treat a list of indices as row access,
    # returning the rows indicated. Anything else is considered columnar
    # access. For columnar access, the return set has an Array for each row
    # with the values indicated by the headers in each Array. You can force
    # column or row mode using by_col!() or by_row!().
    #
    # You cannot mix column and row access.
    #
    def values_at(*indices_or_headers)
      if @mode == :row or  # by indices
         ( @mode == :col_or_row and indices_or_headers.all? do |index|
                                      index.is_a?(Integer)         or
                                      ( index.is_a?(Range)         and
                                        index.first.is_a?(Integer) and
                                        index.last.is_a?(Integer) )
                                    end )
        @table.values_at(*indices_or_headers)
      else                 # by headers
        @table.map { |row| row.values_at(*indices_or_headers) }
      end
    end

    #
    # Adds a new row to the bottom end of this table. You can provide an Array,
    # which will be converted to a CSV::Row (inheriting the table's headers()),
    # or a CSV::Row.
    #
    # This method returns the table for chaining.
    #
    def <<(row_or_array)
      if row_or_array.is_a? Array  # append Array
        @table << Row.new(headers, row_or_array)
      else                         # append Row
        @table << row_or_array
      end

      self # for chaining
    end

    #
    # A shortcut for appending multiple rows. Equivalent to:
    #
    #   rows.each { |row| self << row }
    #
    # This method returns the table for chaining.
    #
    def push(*rows)
      rows.each { |row| self << row }

      self # for chaining
    end

    #
    # Removes and returns the indicated columns or rows. In the default mixed
    # mode indices refer to rows and everything else is assumed to be a column
    # headers. Use by_col!() or by_row!() to force the lookup.
    #
    def delete(*indexes_or_headers)
      if indexes_or_headers.empty?
        raise ArgumentError, "wrong number of arguments (given 0, expected 1+)"
      end
      deleted_values = indexes_or_headers.map do |index_or_header|
        if @mode == :row or  # by index
            (@mode == :col_or_row and index_or_header.is_a? Integer)
          @table.delete_at(index_or_header)
        else                 # by header
          if index_or_header.is_a? Integer
            @headers.delete_at(index_or_header)
          else
            @headers.delete(index_or_header)
          end
          @table.map { |row| row.delete(index_or_header).last }
        end
      end
      if indexes_or_headers.size == 1
        deleted_values[0]
      else
        deleted_values
      end
    end

    #
    # Removes any column or row for which the block returns +true+. In the
    # default mixed mode or row mode, iteration is the standard row major
    # walking of rows. In column mode, iteration will +yield+ two element
    # tuples containing the column name and an Array of values for that column.
    #
    # This method returns the table for chaining.
    #
    # If no block is given, an Enumerator is returned.
    #
    def delete_if(&block)
      return enum_for(__method__) { @mode == :row or @mode == :col_or_row ? size : headers.size } unless block_given?

      if @mode == :row or @mode == :col_or_row  # by index
        @table.delete_if(&block)
      else                                      # by header
        deleted = []
        headers.each do |header|
          deleted << delete(header) if yield([header, self[header]])
        end
      end

      self # for chaining
    end

    include Enumerable

    #
    # In the default mixed mode or row mode, iteration is the standard row major
    # walking of rows. In column mode, iteration will +yield+ two element
    # tuples containing the column name and an Array of values for that column.
    #
    # This method returns the table for chaining.
    #
    # If no block is given, an Enumerator is returned.
    #
    def each(&block)
      return enum_for(__method__) { @mode == :col ? headers.size : size } unless block_given?

      if @mode == :col
        headers.each { |header| yield([header, self[header]]) }
      else
        @table.each(&block)
      end

      self # for chaining
    end

    # Returns +true+ if all rows of this table ==() +other+'s rows.
    def ==(other)
      return @table == other.table if other.is_a? CSV::Table
      @table == other
    end

    #
    # Returns the table as an Array of Arrays. Headers will be the first row,
    # then all of the field rows will follow.
    #
    def to_a
      array = [headers]
      @table.each do |row|
        array.push(row.fields) unless row.header_row?
      end

      array
    end

    #
    # Returns the table as a complete CSV String. Headers will be listed first,
    # then all of the field rows.
    #
    # This method assumes you want the Table.headers(), unless you explicitly
    # pass <tt>:write_headers => false</tt>.
    #
    def to_csv(write_headers: true, **options)
      array = write_headers ? [headers.to_csv(**options)] : []
      @table.each do |row|
        array.push(row.fields.to_csv(**options)) unless row.header_row?
      end

      array.join("")
    end
    alias_method :to_s, :to_csv

    #
    # Extracts the nested value specified by the sequence of +index+ or +header+ objects by calling dig at each step,
    # returning nil if any intermediate step is nil.
    #
    def dig(index_or_header, *index_or_headers)
      value = self[index_or_header]
      if value.nil?
        nil
      elsif index_or_headers.empty?
        value
      else
        unless value.respond_to?(:dig)
          raise TypeError, "#{value.class} does not have \#dig method"
        end
        value.dig(*index_or_headers)
      end
    end

    # Shows the mode and size of this table in a US-ASCII String.
    def inspect
      "#<#{self.class} mode:#{@mode} row_count:#{to_a.size}>".encode("US-ASCII")
    end
  end
end
