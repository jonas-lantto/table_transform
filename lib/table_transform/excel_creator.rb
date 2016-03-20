require 'write_xlsx'
require_relative 'table'


module TableTransform

  # Creates excel file
  class ExcelCreator
    def initialize(filename)
      @workbook = WriteXLSX.new(filename)
      @formats = {}
    end

    def create!
      @workbook.close
    end

    def add_tab(name, table)
      set_formats(table.column_properties) if table.is_a?(TableTransform::Table)
      create_table(name, table)
    end

    #################################
    private

    def self.default_properties(table_name)
      TableTransform::Table::TableProperties.new(
          {
              name: table_name.tr(' ', '_'),
              auto_filter: true
          }
      )
    end

    # estimated column width of format
    def self.format_column_size(format)
      return 0 if format.nil?
      f = format.gsub(/\[.*?\]/, '').split(';')
      f.map{|x| x.size}.max
    end

    # @return array with column width per column
    def self.column_width(table, auto_filter_correct = true, max_width = 100)
      return [] unless table.is_a? TableTransform::Table
      data = table.to_a

      auto_filter_size_correction = auto_filter_correct ? 3 : 0
      res = Array.new(data.first.map { |name|
        [name.to_s.size + auto_filter_size_correction, format_column_size(table.column_properties[name][:format])].max
      })
      data.each { |row|
        row.each_with_index { |cell, column_no|
          res[column_no] = [cell.to_s.size, res[column_no]].max
        }
      }
      res.map! { |x| [x, max_width].min }
    end

    def set_formats(column_properties)
      # find all :formats across all columns
      column_properties.each{|_,v|
        f = v[:format]
        @formats[f] ||= @workbook.add_format(:num_format => f) unless f.nil?
      }
    end

    def create_column_metadata(column_properties, formats, formulas)
      res = []
      column_properties.each{ |header_name, data|
        col_props = TableTransform::Properties.new data.to_h

        #format (replace str format with excel representation)
        col_props.update({format: formats[col_props[:format]]}) unless col_props[:format].nil?

        #formula
        formula = formulas[header_name]
        col_props.update({formula: formula}) unless formula.nil?

        #header
        col_props.update({header: header_name})
        res << col_props.to_h
      }
      res
    end

    def create_table(name, table)
      worksheet = @workbook.add_worksheet(name)
      data = table.to_a
      return if data.nil? or data.empty? # Create empty worksheet if no data

      properties = ExcelCreator::default_properties(name).update(table.table_properties.to_h)
      col_width = ExcelCreator::column_width(table, properties[:auto_filter])

      header = data.shift
      data << [nil] * header.count if data.empty? # Add extra row if empty

      worksheet.add_table(
          0, 0, data.count, header.count - 1,
          {
              :name => properties[:name],
              :data => data,
              :autofilter => properties[:auto_filter] ? 1 : 0,
              :columns => create_column_metadata(table.column_properties, @formats, table.formulas)
          }
      )

      # Set column width
      col_width.each_with_index { |size, column| worksheet.set_column(column, column, size) }
    end
  end
end
