require 'csv'
require_relative 'properties'

module TableTransform
  module Util
    def self.get_col_index(col_name, data)
      data[col_name] || (raise "No column with name '#{col_name}' exists")
    end
  end

  class Table
    attr_reader :formulas
    attr_reader :table_properties
    attr_reader :column_properties

    def self.create_from_file(file_name, sep = ',')
      rows = CSV.read(file_name, { :col_sep => sep })
      raise "'#{file_name}' contains no data" if rows.empty?

      Table.new(rows)
    end

    def self.create_empty(header, table_properties = {})
      raise 'Table header need to be array' unless header.is_a? Array
      raise 'Table, No header defined' if header.empty?
      Table.new([header], table_properties)
    end

    # @throws if column names not unique
    # @throws if column size for each row match
    def initialize(rows, table_properties = {})
      raise 'Table required to have at least a header row' if (rows.nil? or rows.empty?)

      @data_rows = rows.clone
      header = @data_rows.shift
      @column_indexes = create_column_name_binding(header)
      @formulas = {}
      @table_properties = TableProperties.new(table_properties)
      @column_properties = Hash.new{|_hash, key| raise "No column with name '#{key}' exists"}
      create_column_properties(*header,{})

      validate_header_uniqueness(header)
      validate_column_size
    end

    # Sets metadata for given columns
    # Example:
    #  set_metadata('Col1', {format: '#,##0'})
    def set_metadata(*columns, metadata)
      warn 'set_metadata is deprecated. Use column_properties[] instead'
      columns.each{|c| @column_properties[c].reset(metadata)}
    end

    # Returns meta data as Hash with header name as key
    def metadata
      warn 'metadata is deprecated. Use column_properties[] instead'
      @column_properties.inject({}){|res, (k, v)| res.merge!({k => v.to_h})}
    end

    def add_column_formula(column, formula, column_properties = {})
      add_column(column, column_properties){nil}
      @formulas[column] = formula
      self # self chaining
    end

    def << (hash_values)
      @data_rows << create_row(hash_values)
      self
    end

    # Add two tables
    # @throws if header or properties do not match
    def +(table)
      t2 = table.to_a
      t2_header = t2.shift
      raise 'Tables cannot be added due to header mismatch' unless @column_properties.keys == t2_header
      raise 'Tables cannot be added due to column properties mismatch' unless column_properties_eql? table.column_properties
      raise 'Tables cannot be added due to table properties mismatch' unless @table_properties.to_h == table.table_properties.to_h
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
      res.unshift @column_properties.keys.clone
    end

    # @returns new table with specified columns specified in given header
    def extract(header)
      validate_column_exist(*header)
      selected_cols = @column_indexes.values_at(*header)
      t = Table.new( @data_rows.inject([header]) {|res, row| (res << row.values_at(*selected_cols))}, @table_properties.to_h )
      header.each{|h| t.column_properties[h].reset(@column_properties[h].to_h)}
      t.formulas = header.zip(@formulas.values_at(*header)).to_h
      t
    end

    # @returns new table with rows that match given block
    def filter
      t = Table.new( (@data_rows.select {|row| yield Row.new(@column_indexes, row)}.unshift @column_properties.keys.clone), @table_properties.to_h )
      t.formulas = @formulas.clone
      t
    end

    #adds a column with given name to the far right of the table
    #@throws if given column name already exists
    def add_column(name, column_properties = {})
      validate_column_absence(name)
      create_column_properties(name, column_properties)
      @data_rows.each{|x|
        x << (yield Row.new(@column_indexes, x))
      }
      @column_indexes[name] = @column_indexes.size
      self # enable chaining
    end

    def change_column(name)
      raise "Column with formula('#{name}') cannot be changed" if @formulas[name]
      index = Util::get_col_index(name, @column_indexes)
      @data_rows.each{|r|
        r[index] = yield Row.new(@column_indexes, r)
      }

      self # enable chaining
    end

    def delete_column(*names)
      validate_column_exist(*names)
      names.each{|n|
        @column_properties.delete(n)
        @formulas.delete(n)
      }

      selected_cols = @column_indexes.values_at(*@column_properties.keys)
      @data_rows.map!{|row| row.values_at(*selected_cols)}

      @column_indexes = create_column_name_binding(@column_properties.keys)
      self
    end

    def rename_column(from, to)
      validate_column_exist(from)
      validate_column_absence(to)

      @column_properties = @column_properties.map{|k,v| [k == from ? to : k, v] }.to_h
      @formulas = @formulas.map{|k,v| [k == from ? to : k, v] }.to_h
      @column_indexes = create_column_name_binding(@column_properties.keys)
    end

    # Table row
    # Columns within row can be referenced by name, e.g. row['name']
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

    # Cell within Table::Row
    class Cell < String
      # @returns true if this cell includes any of the given values in list
      def include_any?(list)
        list.inject(false){|res, x| res | (self.include? x)}
      end
    end

    # Table properties
    class TableProperties < TableTransform::Properties
      def validate(properties)
        super
        properties.each { |k, v|
          case k
            when :name
              raise "Table property '#{k}' expected to be a non-empty string" unless v.is_a?(String) && !v.empty?
            when :auto_filter
              raise "Table property '#{k}' expected to be a boolean" unless !!v == v
            else
              raise "Table property unknown '#{k}'"
          end
        }
      end
    end

    # Column properties
    class ColumnProperties < TableTransform::Properties
      def validate(properties)
        super
        properties.each { |k, v|
          case k
            when :format
              raise "Column property 'format' expected to be a non-empty string" unless v.is_a?(String) && !v.empty?
            else
              raise "Unknown column property '#{k}'"
          end
        }
      end
    end


    protected
      attr_writer :formulas

    private
      def create_column_name_binding(header_row)
        header_row.map.with_index{ |x, i| [x, i] }.to_h
      end

      def create_row(hash_values)
        @column_properties.keys.inject([]) { |row, col| row << hash_values.fetch(col){raise "Value for column '#{col}' could not be found"} }
      end

      def create_column_properties(*header, properties)
        header.each{|key| @column_properties.store(key, TableTransform::Table::ColumnProperties.new(properties))}
      end

      def column_properties_eql?(column_properties)
          return false unless @column_properties.size == column_properties.size
          @column_properties.each{|key, prop| return false unless prop.to_h == column_properties[key].to_h}
      end

      # @throws unless all header names are unique
      def validate_header_uniqueness(header)
        dup = header.select{ |e| header.count(e) > 1 }.uniq
        raise "Column(s) not unique: #{dup.map{|x| "'#{x}'"}.join(', ')}" if dup.size > 0
      end

      # @throws unless all rows have same number of elements
      def validate_column_size
        @data_rows.each_with_index {|x, index| raise "Column size mismatch. On row #{index+1}. Size #{x.size} expected to be #{@column_properties.size}" if @column_properties.size != x.size}
      end

      def validate_column_exist(*names)
        diff = names - @column_properties.keys
        raise raise "No column with name '#{diff.first}' exists" if diff.size > 0
      end

      def validate_column_absence(name)
        raise "Column '#{name}' already exists" if @column_properties.keys.include?(name)
      end

  end
end