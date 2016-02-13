require 'write_xlsx'

module TableTransform
  module ExcelCreator
    module Util
      # @return array with column width per column
      def self.column_width(data, auto_filter_correct = true, max_width = 100)
        return [] if data.empty?

        auto_filter_size_correction = auto_filter_correct ? 3 : 0

        res = Array.new(data.first.map { |x| x.to_s.size + auto_filter_size_correction })
        data.each { |row|
          row.each_with_index { |cell, column_no|
            res[column_no] = [cell.to_s.size, res[column_no]].max
          }
        }
        res.map! { |x| [x, max_width].min }
      end


      def self.create_table(workbook, name, data)
        worksheet = workbook.add_worksheet(name)
        return if data.nil? or data.empty? # Create empty worksheet if no data

        col_width = column_width(data)

        header = data.shift
        data << [nil] * header.count if data.empty? # Add extra row if empty

        worksheet.add_table(
            0, 0, data.count, header.count - 1,
            {
                :name => name.tr(' ', '_'),
                :data => data,
                :autofilter => 1,
                :columns => header.map { |v| {:header => v} }
            }
        )

        # Set column width
        col_width.each_with_index { |size, column| worksheet.set_column(column, column, size)}
      end
    end

    #Creates excel sheet with given filename and given tab(s)
    def self.create_workbook(filename, tabs = {})
      workbook = WriteXLSX.new(filename)
      tabs.each { |name, data|
        Util::create_table(workbook, name, data)
      }
      workbook.close
    end
  end
end