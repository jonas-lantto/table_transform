module TableTransform

  # Help functions to create formulas
  module FormulaHelper
    # Reference a table
    def self.table(name)
      "#{name}[]"
    end

    # Reference a column in same table
    def self.column(name)
      "[#{name}]"
    end

    # Quotes text to be used inside formulas
    def self.text(txt)
      "\"#{txt}\""
    end

    # vlookup helper, search for a value in another table with return column specified by name
    def self.vlookup(search_value, table_name, return_col_name)
      "VLOOKUP(#{search_value},#{table(table_name)},COLUMN(#{table_name}[[#Headers],#{column(return_col_name)}]),FALSE)"
    end
  end
end