require 'csv'

module TableTransform
  module Util
    def self.get_col_index(col_name, data)
      data[col_name] || (raise "No column with name '#{col_name}' exists")
    end
  end

  class Table
    def self.create_from_file(file_name, sep = ',')
      rows = CSV.read(file_name, { :col_sep => sep })
      raise "'#{file_name}' contains no data" if rows.empty?

      Table.new(rows)
    end

    def self.create_empty(header)
      raise 'Table header need to be array' unless header.is_a? Array
      raise 'Table, No header defined' if header.empty?
      Table.new([header])
    end

    # @throws if column names not unique
    # @throws if column size for each row match
    def initialize(rows)
      raise 'Table required to have at least a header row' if (rows.nil? or rows.empty?)

      @data_rows = rows.clone
      header = @data_rows.shift
      @column_indexes = create_column_name_binding(header)
      @metadata = header.zip( Array.new(header.size){{}} ).to_h

      validate_header_uniqueness(header)
      validate_column_size
    end

    def add_format(format, *columns)
      columns.each{|col| @metadata[col].merge!({format: format})}
    end

    def metadata
      @metadata.clone
    end

    def << (hash_values)
      @data_rows << create_row(hash_values)
      self
    end

    # Add two tables
    # @throws if header do not match
    def +(table)
      t2 = table.to_a
      t2_header = t2.shift
      raise 'Tables cannot be added due to header mismatch' if @metadata.keys != t2_header
      TableTransform::Table.new(self.to_a + t2)
    end

    def each_row
      @data_rows.each{|x|
        yield Row.new(@column_indexes, x)
      }
    end

    # @returns array of data arrays including header row
    def to_a
      res = @data_rows.clone
      res.unshift @metadata.keys.clone
    end

    # @returns new table with specified columns specified in given header
    def extract(header)
      selected_cols = header.inject([]) { |res, c| res << Util::get_col_index(c, @column_indexes) }
      t = Table.new( @data_rows.inject([header]) {|res, row| (res << row.values_at(*selected_cols))} )
      t.metadata = t.metadata.keys.zip(@metadata.values_at(*header)).to_h
      t
    end

    # @returns new table with rows that match given block
    def filter
      Table.new( @data_rows.select {|row| yield Row.new(@column_indexes, row)}.unshift @metadata.keys.clone )
    end

    #adds a column with given name to the far right of the table
    #@throws if given column name already exists
    def add_column(name)
      raise "Column '#{name}' already exists" if @metadata.keys.include?(name)
      @metadata[name] = {}
      @data_rows.each{|x|
        x << (yield Row.new(@column_indexes, x))
      }
      @column_indexes[name] = @column_indexes.size
      self # enable chaining
    end

    def change_column(name)
      index = Util::get_col_index(name, @column_indexes)
      @data_rows.each{|r|
        r[index] = yield Row.new(@column_indexes, r)
      }
      self # enable chaining
    end

    def delete_column(*names)
      names.each{|n| Util::get_col_index(n, @column_indexes); @metadata.delete(n)}

      selected_cols = @metadata.keys.inject([]) { |res, c| res << Util::get_col_index(c, @column_indexes) }
      @data_rows.map!{|row| row.values_at(*selected_cols)}

      @column_indexes = create_column_name_binding(@metadata.keys)
      self
    end

    # @throws unless all header names are unique
    private def validate_header_uniqueness(header)
      dup = header.select{ |e| header.count(e) > 1 }.uniq
      raise "Column #{dup.map{|x| "'#{x}'"}.join(' and ')} not unique" if dup.size > 0
    end

    # @throws unless all rows have same number of elements
    private def validate_column_size
      @data_rows.each_with_index {|x, index| raise "Column size mismatch. On row #{index+1}. Size #{x.size} expected to be #{@metadata.size}" if @metadata.size != x.size}
    end

    class Row

      def initialize(cols, row)
        @cols = cols #column name and index in row
        @row  = row  #Specific row
      end

      # @returns row value with column name or empty string if it does not exist
      # @throws exception if column name does not exist
      def [](column_name)
        index = Util::get_col_index(column_name, @cols)
        Cell.new @row[ index ].to_s || ''
      end

    end

    class Cell < String
      # @returns true if this cell includes any of the given values in list
      def include_any?(list)
        list.inject(false){|res, x| res | (self.include? x)}
      end
    end

    protected
      attr_writer :metadata

    private
      def create_column_name_binding(header_row)
        header_row.map.with_index{ |x, i| [x, i] }.to_h
      end

      def create_row(hash_values)
        @metadata.keys.inject([]) { |row, col| row << hash_values.fetch(col){raise "Value for column '#{col}' could not be found"} }
      end
  end
end