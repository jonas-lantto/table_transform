require 'csv'

module TableTransform
  module Util
    def self.get_col_index(col_name, data)
      pos = data[col_name]
      raise "No column with name '#{col_name}' exists" if pos.nil?
      pos
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
      @data_rows = rows.clone
      @header = @data_rows.shift
      @column_indexes = create_column_name_binding(@header)
      dup = @header.select{ |e| @header.count(e) > 1 }.uniq
      raise "Column #{dup.map{|x| "'#{x}'"}.join(' and ')} not unique" if dup.size > 0
      @data_rows.each_with_index {|x, index| raise "Column size mismatch. On row #{index+1}. Size #{x.size} expected to be #{@header.size}" if @header.size != x.size}
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
      raise 'Tables cannot be added due to header mismatch' if @header != t2_header
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
      res.unshift @header
    end

    # @returns new table with specified columns specified in given header
    def extract(header)
      selected_cols = header.inject([]) { |res, c| res << Util::get_col_index(c, @column_indexes) }
      Table.new( @data_rows.inject([header]) {|res, row| (res << row.values_at(*selected_cols))} )
    end

    # @returns new table with rows that match given value in given column_name
    def filter(column_name, value)
      filter_column = Util::get_col_index(column_name, @column_indexes)
      Table.new( @data_rows.select {|row| row[filter_column] == value}.unshift @header.clone )
    end

    #adds a column with given name to the far right of the table
    #@throws if given column name already exists
    def add_column(name)
      raise "Column '#{name}' already exists" if @header.include?(name)
      @header << name
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
      delete_indexes = names.inject([]){|res, n| res << Util::get_col_index(n, @column_indexes)}
      delete_indexes.sort!.reverse!
      delete_indexes.each{|i| @header.delete_at(i)}

      selected_cols = @header.inject([]) { |res, c| res << Util::get_col_index(c, @column_indexes) }
      @data_rows.map!{|row| row.values_at(*selected_cols)}

      @column_indexes = create_column_name_binding(@header)
      self
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
        Cell.new (@row[ index ].to_s || '')
      end

    end

    class Cell < String
      # @returns true if this cell includes any of the given values in list
      def include_any?(list)
        list.inject(false){|res, x| res | (self.include? x)}
      end
    end

    private
      def create_column_name_binding(header_row)
        cols = Hash.new
        header_row.each_with_index { |x, index | cols[x] = index }
        cols
      end

      def create_row(hash_values)
        @header.inject([]) { |row, col| row << (hash_values[col] || '') }
      end
  end
end