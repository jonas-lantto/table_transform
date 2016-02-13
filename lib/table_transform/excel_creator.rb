require 'write_xlsx'


module TableTransform

  # Creates excel file
  class ExcelCreator
    def initialize(filename)
      @workbook = WriteXLSX.new(filename)
      ObjectSpace.define_finalizer(self, self.class.finalize(@workbook))
    end

    def self.finalize(workbook)
      proc { workbook.close }
    end

    def close
      @workbook.close
    end

    def add_tab(name, table)
      create_table(name, table.to_a)
    end


    private

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

    def create_table(name, data)
      worksheet = @workbook.add_worksheet(name)
      return if data.nil? or data.empty? # Create empty worksheet if no data

      auto_filter = true
      col_width = ExcelCreator::column_width(data, auto_filter)

      header = data.shift
      data << [nil] * header.count if data.empty? # Add extra row if empty

      worksheet.add_table(
          0, 0, data.count, header.count - 1,
          {
              :name => name.tr(' ', '_'),
              :data => data,
              :autofilter => auto_filter ? 1 : 0,
              :columns => header.map { |v| {:header => v} }
          }
      )

      # Set column width
      col_width.each_with_index { |size, column| worksheet.set_column(column, column, size) }
    end
  end
end
