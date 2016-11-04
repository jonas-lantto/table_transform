# TableTransform
[![Gem Version](https://badge.fury.io/rb/table_transform.svg)](http://badge.fury.io/rb/table_transform)
[![Build Status](https://travis-ci.org/jonas-lantto/table_transform.svg)](https://travis-ci.org/jonas-lantto/table_transform)
[![Code Climate](https://codeclimate.com/github/jonas-lantto/table_transform/badges/gpa.svg)](https://codeclimate.com/github/jonas-lantto/table_transform)
[![Test Coverage](https://codeclimate.com/github/jonas-lantto/table_transform/badges/coverage.svg)](https://codeclimate.com/github/jonas-lantto/table_transform/coverage)
[![Issue Count](https://codeclimate.com/github/jonas-lantto/table_transform/badges/issue_count.svg)](https://codeclimate.com/github/jonas-lantto/table_transform)

Utility to work with csv type data in a name safe environment with utilities to transform data

## Installation

Add this line to your application's Gemfile:

    gem 'table_transform'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install table_transform

## Usage

### Create and populate

    # Create from file
    t = TableTransform::Table::create_from_file('data.csv')

    # Create empty table with given column names 
    t = TableTransform::Table::create_empty(%w(Col1 Col2))
    t << {'Col1' => 1, 'Col2' => 2}

    # Create from an array of arrays. First row column names
    data = [ %w(Name Age), %w(Jane 22)]
    t = TableTransform::Table.new(data)

### Transform
    # Add a new column to the far right
    t.add_column('NameLength'){|row| row['Name'].size}

    # Change values in existing column
    t.change_column('Age'){|row| row['Age'].to_i}
    
    # Will remove given columns. One or several can be specified.
    t.delete_column('Name', 'Address')
    
    # Rename column
    r.rename_column('Age', 'Years')
    
    # Create a new Table with given column in specified order
    t2 = t.extract(%w(Length Name))
    
    # Filter to a new table 
    t2 = t.filter{|row| row['Age'].to_i > 20}

    # Adds rows of two tables with same header
    t1 = TableTransform::Table::create_empty(%w(Col1 Col2))
    t2 = TableTransform::Table::create_empty(%w(Col1 Col2))
    t3 = t1 + t2

### Inspect and traverse
    # Loop through all rows
    t.each_row{|row| puts row['Rebate'].to_f * row['Price'].to_f}

#### Table::Row
`Table::each_row` return a `Table::Row`<br/>
A row can access its values by column name e.g. `row['Name']`<br/>
If column name does not exist (case sensitive) an exception is raised

#### Table:Cell
    # Table::Cell < String
    row['operating_system'].downcase == 'centos'

    # include_any?
    c = row['Col1']                # c = 'CHECK'
    c.include_any?(%w(AA EC DD)))  # true

### Properties
There are two categories of properties, Table and Column<br/>
Same interface for interacting with properties
    
    # Update - add or update :name property in existing p
    p.update({name: 'xxx'})
    
    # Reset - resets p with given property, clearing previous properties 
    p.reset({name: 'xxx'})
    
    # Delete
    p.delete(:name)
    
    # Each
    p.each{|x| ...}
    
    # Access
    p[:name]
    
#### Table properties
    # Set table name - override default name
    t.table_properties.update({name: 'Table1'})
    
    # Set turn on/off auto filter button
    t.table_properties.update({auto_filter: false})

#### Column properties   
    # Set format for one column
    t.column_properties['Tax'].update({format: '0.0%'})
 
    # Extract properties
    t.column_properties['Tax'] # {format: '0.0%'}
    
    # Add property during add_column
    t.add_column('Tax', {format: '0.0%'}){|row| 0.25}
    
### Formula
Formulas can be added to columns. They have to be in US locale. 
Column values will be nil if inspected

    # Add formula to column
    t.add_column_formula('OnePlusOne', '1+1')

    # Add formula to column with meta data
    t.add_column_formula('OnePlusOne', '1+1', {format: '0.0'})

#### Formula helper
To aid when creating formulas there are a few helpers available
    
    f = TableTransform::FormulaHelper # Namespace alias
    
    # Column
    f::column('price') # <=> '[price]'
    t.add_column_formula('Total value', "#{f::column('price')} * #{f::column('volume')}")

    # Table
    f::table('Table1') # <=> 'Table1[]'
    
    # Text (will avoid the clutter of protecting " character)
    f::text('No') # <=> '"No"'
    
    # VLOOKUP, convenience function to extract values from another table
    # Finds the street name in table Address for name specified in column Name
    f::vlookup(f::column('Name'), 'Address', 'Street'))
    f::vlookup('[Name]', 'Address', 'Street'))

    # Finds the number of pets in Table Pets for name specified in column Name. If name does not exist it defaults to 0
    f::vlookup(f::column('Name'), 'Pets', 'nPets', 0))
    f::vlookup('[Name]', 'Pets', 'nPets', 0))


### Publish
    # Export as array
    t.to_a

    # Excel sheet
    excel = TableTransform::ExcelCreator.new('output.xlsx')
    excel.add_tab('Result', t)
    excel.create!

#### Excel Creator
Will create an Excel Table on each tab. Name of the table will be the same as the sheet (except space replaced
with _)

Each column will be auto scaled to an approximate size based on column content.
     
## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/jonas-lantto/table_transform).


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

