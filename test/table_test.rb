require_relative 'test_helper'
require 'benchmark'
require 'table_transform/table'
require 'yaml'


class TableTest < Minitest::Test

  def test_initialize
    data = [
        %w(Name Age),
        %w(Jane 22)
    ]

    # successful creation
    TableTransform::Table.new(data)
    assert_equal(data, data.to_a)

    #too many elements in data row
    d2 = data.clone
    d2 << %w(Jane 22 AA)
    e = assert_raises{ TableTransform::Table.new(d2) }
    assert_equal('Column size mismatch. On row 2. Size 3 expected to be 2', e.to_s)

    #too few elements in data row
    d2 = data.clone
    d2 << %w(A B)
    d2 << %w(Jane)
    e = assert_raises{ TableTransform::Table.new(d2) }
    assert_equal('Column size mismatch. On row 3. Size 1 expected to be 2', e.to_s)

    # Nil and empty input
    e = assert_raises{ TableTransform::Table.new(nil) }
    assert_equal('Table required to have at least a header row', e.to_s)
    e = assert_raises{ TableTransform::Table.new([]) }
    assert_equal('Table required to have at least a header row', e.to_s)
  end

  def test_create_from_file
    t = TableTransform::Table::create_from_file('./test/data/test_data.csv')
    assert_equal([%w(A B C),
                  %w(1 2 3),
                  ['A A', 'B B', 'C C']],
                 t.to_a)

    t2 = TableTransform::Table::create_from_file('./test/data/test_data.tsv', "\t")
    assert_equal([%w(A B C),
                  %w(1 2 3),
                  ['A A', 'B B', 'C C']],
                 t2.to_a)

    e = assert_raises{ TableTransform::Table.create_from_file('./test/data/empty_file.csv') }
    assert_equal("'./test/data/empty_file.csv' contains no data", e.to_s)
  end

  def test_create_empty
    # vanilla - success
    t = TableTransform::Table.create_empty(%w(Col1 Col2))
    assert_equal([%w(Col1 Col2)], t.to_a)

    t = TableTransform::Table.create_empty(%w(Col1 Col2), {name: 'Table1'})
    assert_equal([%w(Col1 Col2)], t.to_a)
    assert_equal({name: 'Table1'}, t.table_properties.to_h)

    # non-array header
    e = assert_raises{ TableTransform::Table.create_empty('str') }
    assert_equal('Table header need to be array', e.to_s)

    e = assert_raises{ TableTransform::Table.create_empty(2) }
    assert_equal('Table header need to be array', e.to_s)

    e = assert_raises{ TableTransform::Table.create_empty(nil) }
    assert_equal('Table header need to be array', e.to_s)

    # Array have to be > 0 in size
    e = assert_raises{ TableTransform::Table.create_empty([]) }
    assert_equal('Table, No header defined', e.to_s)
  end

  def test_each_row
    data = [
        %w(Name Age),
        %w(Jane 22),
        ['Joe',   nil]
    ]
    t = TableTransform::Table.new(data)

    assert_equal(data, t.to_a)

    rows = Array.new
    t.each_row{|r| rows << r}

    assert_equal(2, rows.size)
    assert_equal(rows[0].class, TableTransform::Table::Row)
    assert_equal(rows[0]['Name'].class, TableTransform::Table::Cell)
    assert_equal(rows[0]['Name'], 'Jane')
    assert_equal(rows[0]['Age'],  '22')
    assert_equal(rows[1]['Name'], 'Joe')
    assert_equal(rows[1]['Age'],  '', 'Nil should be empty str')

    #fails on unknown columns
    e = assert_raises{ rows[0]['xxx'] }
    assert_equal("No column with name 'xxx' exists", e.to_s)

    #case sensitive
    e = assert_raises{ rows[0]['name'] }
    assert_equal("No column with name 'name' exists", e.to_s)
  end

  def test_enforce_column_name_uniq
    # initialize validation single
    data = [%w(Age Age),
            %w(22  23)]
    e = assert_raises{ TableTransform::Table.new(data) }
    assert_equal("Column(s) not unique: 'Age'", e.to_s)

    # initialize validation multiple
    data = [%w(Age Age Name Name),
            %w(22  23 A B)]
    e = assert_raises{ TableTransform::Table.new(data) }
    assert_equal("Column(s) not unique: 'Age', 'Name'", e.to_s)

    # Add column
    t = TableTransform::Table::create_empty(%w(Name Age))
    e = assert_raises{ t.add_column('Age'){} }
    assert_equal("Column 'Age' already exists", e.to_s)
  end

  def test_extract
    t = TableTransform::Table.create_empty(%w(Name Age Length))
    t << {'Name' => 'Joe',  'Age' => 20, 'Length' => 170}
    t << {'Name' => 'Jane', 'Age' => 45, 'Length' => 172}

    t2 = t.extract(%w(Length Name))
    assert_kind_of(TableTransform::Table, t2)
    assert_equal(t.to_a.size, t2.to_a.size, 'Number of rows are the same')
    assert_equal(2, t2.to_a.first.size)
    assert_equal(2, t2.to_a.last.size)
    assert_equal(172,    t2.to_a.last[0], 'Row order and type preserved')
    assert_equal('Jane', t2.to_a.last[1], 'Row order and type preserved')

    # Columns must exist
    e = assert_raises{ t.extract(%w(Name xxx)) }
    assert_equal("No column with name 'xxx' exists", e.to_s)
  end

  def test_filter
    t_orig = TableTransform::Table.create_empty(%w(Name Age Length))
    t_orig << {'Name' => 'Joe',  'Age' => 20, 'Length' => 170}
    t_orig << {'Name' => 'Jane', 'Age' => 45, 'Length' => 172}
    t_orig << {'Name' => 'Anna', 'Age' => 20, 'Length' => 165}

    t2 = t_orig.filter{|row| row['Age'].to_i <= 20}
    assert_kind_of(TableTransform::Table, t2)
    assert_equal(3, t2.to_a.size, 'Header row + filtered rows')
    assert( not(t2.to_a.flatten.include? ('Jane')), 'Value should be filtered out')
    assert_equal('Anna', t2.to_a.last[0], 'Row order and type preserved')
    assert_equal(165,    t2.to_a.last[2], 'Row order and type preserved')

    t2 = t_orig.filter{ false }
    assert_equal(1, t2.to_a.size, 'Header row only')

    # Chain filter and extract
    t2 = t_orig.filter{|row| row['Age'].to_i == 45}.extract(%w(Name))
    assert_kind_of(TableTransform::Table, t2)
    assert_equal(2, t2.to_a.size, 'Header row + filtered row')
    assert_equal(1, t2.to_a.last.size, 'Only one column')
    assert_equal('Jane', t2.to_a.last[0])

    # Formula and column properties remain after filter
    t3 = t_orig.add_column_formula('OnePlusOne', '1+1')
    t3.column_properties['Age'].update({format: '#,##0'})
    t3 = t3.filter{|row| row['Age'].to_i == 45}
    assert_equal(1, t3.formulas.size)
    assert_equal('1+1', t3.formulas['OnePlusOne'])
    assert_equal({format: '#,##0'}, t3.column_properties['Age'].to_h)

    # Columns must exist
    e = assert_raises{ t_orig.filter{|row| row['xxx'] == ''} }
    assert_equal("No column with name 'xxx' exists", e.to_s)

    # Non destructive
    data_target = [
        %w(Name Age),
        ['Jane',  44],
        ['Joe',   nil]
    ]
    t = TableTransform::Table.new(Marshal.load( Marshal.dump(data_target) ))
    t.filter{|row| row['Age'].to_i == 20}.delete_column('Age')
    assert_equal(data_target, t.to_a)
  end

  def test_op_plus
    #vanilla
    t1 = TableTransform::Table.create_empty(%w(Name Age Length))
    t1 << {'Name' => 'Joe',  'Age' => 20, 'Length' => 170}

    t2 = TableTransform::Table.create_empty(%w(Name Age Length))
    t2 << {'Name' => 'Jane',  'Age' => 45, 'Length' => 172}

    assert_equal([%w(Name Age Length),
                  ['Joe', 20, 170],
                  ['Jane', 45, 172]],
                 (t1 + t2).to_a)

    #header mismatch
    t1 = TableTransform::Table.create_empty(%w(Name Age Length))
    t2 = TableTransform::Table.create_empty(%w(Name Length Age))
    e = assert_raises{ t1 + t2 }
    assert_equal('Tables cannot be added due to header mismatch', e.to_s)

    #header mismatch - properties
    t1 = TableTransform::Table.create_empty(%w(Name Age Length))
    t2 = TableTransform::Table.create_empty(%w(Name Age Length))
    t1.column_properties['Age'].update({format: '#,##0'})
    e = assert_raises{ t1 + t2 }
    assert_equal('Tables cannot be added due to column properties mismatch', e.to_s)
  end

  def numformat(num)
    num.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1 ")
  end

  def test_bench
    t = TableTransform::Table.create_empty(%w(Name Age Length))
    n = 1_000
    n.times { t << {'Name' => 'Joe', 'Age' => 20, 'Length' => 170}}

    time = Benchmark.realtime { t.extract(%w(Name Length)) }
    puts "Extract/sec: #{numformat((n / time).to_i)}"

    time = Benchmark.realtime { t.filter{|row| row['Name'] == 'Joe' } }
    puts "Filter/sec: #{numformat((n / time).to_i)}"

    time = Benchmark.realtime { t.add_column('Age x 2'){|row| row['Age'] * 2} }
    puts "Adds/sec: #{numformat((n / time).to_i)}"

  end

  def test_add_column
    data = [
        %w(Name Age),
        %w(Jane 22),
        ['Joe',   nil]
    ]
    t = TableTransform::Table.new(data)

    result = t.add_column('NameLength'){|row| row['Name'].size}
    assert_kind_of(TableTransform::Table, result, 'Self chaining')
    assert_equal('NameLength', t.to_a[0][2])
    assert_equal(4, t.to_a[1][2])

    t.each_row{|r| assert_equal(r['Name'].size, r['NameLength'].to_i)}

    # Set meta data
    t.add_column('Tax', {format: '0.0%'}){ 0.25 }
    assert_equal({format: '0.0%'}, t.column_properties['Tax'].to_h)

    # Set meta data, verify meta data verification
    e = assert_raises{ t.add_column('Tax2', {format2: '0.0%'}){ 0.25 } }
    assert_equal("Unknown column property 'format2'", e.to_s)
  end

  def test_change_column
    data = [
        %w(Name Age),
        %w(Jane 22),
        ['Joe',   nil]
    ]
    t = TableTransform::Table.new(data)
    result = t.change_column('Age'){|row| row['Age'].to_i * 2 unless row['Age'].empty?}
    assert_kind_of(TableTransform::Table, result, 'Self chaining')

    data_target = [
        %w(Name Age),
        ['Jane',  44],
        ['Joe',   nil]
    ]
    assert_equal(data_target, t.to_a)

    ages = Array.new
    t.each_row{|r| ages << r['Age']}
    assert_equal([(22 * 2).to_s, ''], ages)

    e = assert_raises{ t.change_column('xxx'){ 'xxx'} }
    assert_equal("No column with name 'xxx' exists", e.to_s)
  end

  def test_delete_column
    t = TableTransform::Table.create_empty(%w(Name Age Length))
    t << {'Name' => 'Joe',  'Age' => 20, 'Length' => 170}
    t << {'Name' => 'Jane', 'Age' => 45, 'Length' => 172}

    result = t.delete_column('Age')
    assert_kind_of(TableTransform::Table, result, 'Self chaining')
    assert_equal([%w(Name Length),
                  ['Joe', 170],
                  ['Jane', 172]],
                 t.to_a)

    t2 = TableTransform::Table.create_empty(%w(Name Age Length Address))
    t2 << {'Name' => 'Joe',  'Age' => 20, 'Length' => 170, 'Address' => 'home'}
    t2 << {'Name' => 'Jane', 'Age' => 45, 'Length' => 172, 'Address' => 'away'}

    t2.delete_column('Name', 'Address')
    assert_equal([%w(Age Length),
                  [20, 170],
                  [45, 172]],
                 t2.to_a)

    e = assert_raises{ t2.delete_column('xxx') }
    assert_equal("No column with name 'xxx' exists", e.to_s)
  end

  def test_rename_column
    t = TableTransform::Table.create_empty(%w(Name Decibel Length))
    t << {'Name' => 'Joe',  'Decibel' => 20, 'Length' => 170}
    assert_equal([%w(Name Decibel Length),
                  ['Joe', 20, 170]],
                 t.to_a)
    t.column_properties['Decibel'].update({format: '###,#'})

    t.rename_column('Decibel', 'SoundLevel')
    assert_equal([%w(Name SoundLevel Length),
                  ['Joe', 20, 170]],
                 t.to_a, 'Order preserved')

    refute_includes(YAML::dump(t), 'Decibel', 'Should not be a trace of Decibel left')

    t = TableTransform::Table.create_empty(%w(Name))
    t.add_column_formula('Decibel', '1+1')
    t.rename_column('Decibel', 'SoundLevel')
    refute_includes(YAML::dump(t), 'Decibel')

    # Validation
    t = TableTransform::Table.create_empty(%w(Decibel))
    e = assert_raises{ t.rename_column('xxx', 'SoundLevel') }
    assert_equal("No column with name 'xxx' exists", e.to_s)

    e = assert_raises{ t.rename_column('Decibel', 'Decibel') }
    assert_equal("Column 'Decibel' already exists", e.to_s)
  end

  def test_cell
    assert_equal('aaa', TableTransform::Table::Cell.new('aaa'))
    assert_equal('', TableTransform::Table::Cell.new)
    assert_equal(String, TableTransform::Table::Cell.new('aaa').class.superclass)

    #include_any?
    assert_equal(true, TableTransform::Table::Cell.new('CHECK').include_any?(%w(AA BB EC DD)))
    assert_equal(false, TableTransform::Table::Cell.new('CHECK').include_any?(%w(AA BB CC DD)))

    assert_equal(true, TableTransform::Table::Cell.new('CHECK').downcase.include_any?(%w(aa bb ec dd)))
    assert_equal(false, TableTransform::Table::Cell.new('CHECK').downcase.include_any?(%w(aa bb cc dd)))

  end

  def test_streaming_of_new_row
    t = TableTransform::Table.create_empty(%w(Severity Category))

    # Vanilla insert
    t << {'Severity' => :alarm, 'Category' => 'External'}
    assert_equal(2, t.to_a.count)
    assert_equal([:alarm, 'External'], t.to_a.last)

    # Vanilla insert reversed order
    t << {'Category' => 'External', 'Severity' => :alarm}
    assert_equal(3, t.to_a.count)
    assert_equal([:alarm, 'External'], t.to_a.last)

    # hash key is missing
    e = assert_raises{ t << {'Severity' => :warning} }
    assert_equal("Value for column 'Category' could not be found", e.to_s)

    # hash value is nil
    t << {'Severity' => :warning, 'Category' => nil}
    assert_equal(4, t.to_a.count)
    assert_equal([:warning, nil], t.to_a.last)

    # streamed values not in specified output columns will not be added
    t << {'Severity' => :warning, 'Category' => 'Extra', 'Dummy' => 'DummyValue'}
    assert_equal(5, t.to_a.count)
    assert_equal([:warning, 'Extra'], t.to_a.last)

    # streaming can be chained
    t << {'Severity' => :normal, 'Category' => 'T1'} << {'Severity' => :normal, 'Category' => 'T2'}
    assert_equal(7, t.to_a.count)
    assert_equal([[:normal, 'T1'], [:normal, 'T2']], t.to_a[-2,2])
  end

  def test_column_properties
    t = TableTransform::Table.create_empty(%w(Name Income Dept Tax))
    t << {'Name' => 'Joe',  'Income' => 500_000,   'Dept' => 43_000,  'Tax' => 0.15}
    t << {'Name' => 'Jane', 'Income' => 1_300_000, 'Dept' => 180_000, 'Tax' => 0.567}

    %w(Income Tax Dept).each{|k| t.column_properties[k].update({format: '#,##0'})}

    # Set and re-set column properties
    assert_equal(4, t.column_properties.size)
    assert_equal({},                t.column_properties['Name'].to_h)
    assert_equal({format: '#,##0'}, t.column_properties['Income'].to_h)
    assert_equal({format: '#,##0'}, t.column_properties['Dept'].to_h)
    assert_equal({format: '#,##0'}, t.column_properties['Tax'].to_h)

    t.column_properties['Tax'].update({format: '0.0%'})
    assert_equal({format: '0.0%'},  t.column_properties['Tax'].to_h)

    # Delete column
    t.delete_column('Dept')
    assert_equal(3, t.column_properties.size)
    e = assert_raises{ t.column_properties['Dept'] }
    assert_equal("No column with name 'Dept' exists", e.to_s)

    # Extract column
    t = t.extract(%w(Name Tax))
    assert_equal(2, t.column_properties.size)
    assert_equal({}, t.column_properties['Name'].to_h)
    assert_equal({format: '0.0%'}, t.column_properties['Tax'].to_h)
  end

  def test_column_properties_validation
    t = TableTransform::Table.create_empty(%w(Name Income Dept Tax))
    t.column_properties['Tax'].update({format: '0.0%'})

    # invalid column name
    e = assert_raises{ t.column_properties['xxx'].update({format: 'xxx'}) }
    assert_equal("No column with name 'xxx' exists", e.to_s)

    # invalid properties
    e = assert_raises{ t.column_properties['Tax'].update(nil) }
    assert_equal('Default properties must be a hash', e.to_s)

    e = assert_raises{ t.column_properties['Tax'].update([]) }
    assert_equal('Default properties must be a hash', e.to_s)

    e = assert_raises{ t.column_properties['Tax'].update({format2: 'xxx', format3: 45}) }
    assert_equal("Unknown column property 'format2'", e.to_s)

    e = assert_raises{ t.column_properties['Tax'].update({format: 34}) }
    assert_equal("Column property 'format' expected to be a non-empty string", e.to_s)

    e = assert_raises{ t.column_properties['Tax'].update({format: ''}) }
    assert_equal("Column property 'format' expected to be a non-empty string", e.to_s)
  end

  def test_formulas
    t = TableTransform::Table.create_empty(%w(Name Income))
    t << {'Name' => 'Joe',  'Income' => 500_000}
    t << {'Name' => 'Jane', 'Income' => 1_300_000}

    assert_equal(0, t.formulas.size)

    # Add formula
    t2 = t.add_column_formula('OnePlusOne', '1+1')
    assert_kind_of(TableTransform::Table, t2)

    assert_equal(1, t.formulas.size)
    assert_equal('1+1', t.formulas['OnePlusOne'])

    # Add formula with format
    t.add_column_formula('TwoPlusTwo', '2+2', {format: '0.0'})
    assert_equal(2, t.formulas.size)
    assert_equal('2+2', t.formulas['TwoPlusTwo'])
    assert_equal({format: '0.0'},  t.column_properties['TwoPlusTwo'].to_h)

    # Delete column
    t.delete_column('OnePlusOne')
    assert_equal(1, t.formulas.size)
    assert_equal(nil, t.formulas['OnePlusOne'])

    # Extract column
    t2 = t.extract(['TwoPlusTwo'])
    assert_equal(1, t2.formulas.size)
    assert_equal('2+2', t2.formulas['TwoPlusTwo'])
    assert_equal({format: '0.0'},  t2.column_properties['TwoPlusTwo'].to_h)

    # Column with formula cannot be changes
    e = assert_raises{ t.change_column('TwoPlusTwo'){ 1 } }
    assert_equal("Column with formula('TwoPlusTwo') cannot be changed", e.to_s)

    # Column name already exists
    e = assert_raises{ t.add_column_formula('Name', '1+1') }
    assert_equal("Column 'Name' already exists", e.to_s)
  end

  def test_table_properties
    # extract
    t = TableTransform::Table.create_empty(%w(Name Age Length))
    t.table_properties.update({name: 'Table1'})
    t2 = t.extract(%w(Length Name))
    assert_equal({name: 'Table1'}, t2.table_properties.to_h)
    refute_equal(t.table_properties.object_id, t2.table_properties.object_id)

    # filter
    t = TableTransform::Table.create_empty(%w(Name Age Length), {name: 'Table2'})
    assert_equal({name: 'Table2'}, t.filter{true}.table_properties.to_h)

    # + operator
    t = TableTransform::Table.create_empty(%w(Name Age Length))
    t2 = TableTransform::Table.create_empty(%w(Name Age Length), {name: 'Table3'})
    e = assert_raises{ t + t2 }
    assert_equal('Tables cannot be added due to table properties mismatch', e.to_s)


  end

  def test_table_properties_validation
    # Properties must be a Hash
    e = assert_raises{ TableTransform::Table::TableProperties.new([]) }
    assert_equal('Default properties must be a hash', e.to_s)

    # Property :name validation
    tp = TableTransform::Table::TableProperties.new({name: 'Table1'})
    assert_equal('Table1', tp[:name])

    e = assert_raises{ TableTransform::Table::TableProperties.new({name: 1}) }
    assert_equal("Table property 'name' expected to be a non-empty string", e.to_s)

    e = assert_raises{ TableTransform::Table::TableProperties.new({name: ''}) }
    assert_equal("Table property 'name' expected to be a non-empty string", e.to_s)

    e = assert_raises{ TableTransform::Table::TableProperties.new({name: nil}) }
    assert_equal("Table property 'name' expected to be a non-empty string", e.to_s)

    # Property :auto_filter validation
    tp = TableTransform::Table::TableProperties.new({auto_filter: true})
    assert_equal(true, tp[:auto_filter])

    e = assert_raises{ TableTransform::Table::TableProperties.new({auto_filter: 1}) }
    assert_equal("Table property 'auto_filter' expected to be a boolean", e.to_s)

    e = assert_raises{ TableTransform::Table::TableProperties.new({auto_filter: nil}) }
    assert_equal("Table property 'auto_filter' expected to be a boolean", e.to_s)

    # Properties validation will require key to exist
    e = assert_raises{ TableTransform::Table::TableProperties.new({xxx: 1}) }
    assert_equal("Table property unknown 'xxx'", e.to_s)
  end

  def test_deprecated
    t = TableTransform::Table::create_empty(%w(A B C D))
    t.set_metadata('B', {format: '###,###'})
    t.set_metadata('A', 'C', {format: '###,000'})
    assert_equal({"A"=>{:format=>"###,000"}, "B"=>{:format=>"###,###"}, "C"=>{:format=>"###,000"}, "D"=>{}}, t.metadata)
  end

end