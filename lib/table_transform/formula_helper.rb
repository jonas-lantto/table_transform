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
    # Use other help functions to create an excel expression
    #
    # @param [excel expression] search_value, value to lookup
    # @param [string]           table_name, name of the table to search in
    # @param [string]           return_col_name, name of the return column in given table
    # @param [excel expression] default, value if nothing was found, otherwise Excel will show N/A
    def self.vlookup(search_value, table_name, return_col_name, default = nil)
      vlookup = "VLOOKUP(#{search_value},#{table(table_name)},COLUMN(#{table_name}[[#Headers],#{column(return_col_name)}]),FALSE)"
      default.nil? ? vlookup : "IFNA(#{vlookup},#{default})"
    end
  end
end