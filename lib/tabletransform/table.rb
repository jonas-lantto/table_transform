require 'csv'

module TableTransform
  module Util
    def self.get_col_index(col_name, data)
      pos = data[col_name.downcase]
      raise "No column with name '#{col_name.downcase}' exists" if pos.nil?
      pos
    end
  end

  class Table
    def self.create_from_file(file_name)
      rows = CSV.read(file_name, { :col_sep => ',' })
      raise "'#{file_name}' contains no data" if rows.empty?

      Table.new(rows)
    end

    def initialize(rows)
      @data_rows = rows.clone
      @header = @data_rows.shift
      @column_indexes = create_column_name_binding(@header)
    end

    def each_row
      @data_rows.each{|x|
        yield Row.new(@column_indexes, x)
      }
    end

    def to_a
      res = @data_rows.clone
      res.unshift @header
    end

    #adds a column with given name to the far right of the table
    def add_column(name)
      @header << name
      @data_rows.each{|x|
        x << (yield Row.new(@column_indexes, x))
      }
      @column_indexes[name.downcase] = @column_indexes.size
      self # enable chaining
    end

    def change_column(name)
      index = Util::get_col_index(name, @column_indexes)
      @data_rows.each{|r|
        r[index] = yield Row.new(@column_indexes, r)
      }
      self # enable chaining
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
      header_row.each_with_index { |x, index | cols[x.downcase] = index }
      cols
    end

  end

end