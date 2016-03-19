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
      set_formats(table.metadata) if table.is_a?(TableTransform::Table)
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
        [name.to_s.size + auto_filter_size_correction, format_column_size(table.metadata[name][:format])].max
      })
      data.each { |row|
        row.each_with_index { |cell, column_no|
          res[column_no] = [cell.to_s.size, res[column_no]].max
        }
      }
      res.map! { |x| [x, max_width].min }
    end

    def set_formats(metadata)
      metadata.each{|_,v|
        f = v[:format]
        @formats[f] ||= @workbook.add_format(:num_format => f) unless f.nil?
      }
    end

    def create_column_metadata(metadata, formats, formulas)
      res = []
      metadata.each{ |header_name, data|
        data_dup = data.to_h.dup
        data_dup[:format] = formats[data_dup[:format]] unless data_dup[:format].nil? #replace str format with excel representation
        formula = formulas[header_name]
        data_dup.merge!({formula: formula}) unless formula.nil?
        res << {header: header_name}.merge(data_dup)
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
              :columns => create_column_metadata(table.metadata, @formats, table.formulas)
          }
      )

      # Set column width
      col_width.each_with_index { |size, column| worksheet.set_column(column, column, size) }
    end
  end
end
