require 'minitest/autorun'
require 'tabletransform/table'


class TableTest < Minitest::Test

  def test_table
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
    assert_equal(rows[0]['Name'].class, TableTransform::Table::Cell)
    assert_equal(rows[0]['Name'], 'Jane')
    assert_equal(rows[0]['Age'],  '22')
    assert_equal(rows[1]['Name'], 'Joe')
    assert_equal(rows[1]['Age'],  '')

    e = assert_raises{ rows[0]['xxx'] }
    assert_equal("No column with name 'xxx' exists", e.to_s)
  end

  def test_create_empty
    # vanilla - success
    t = TableTransform::Table.create_empty(%w(Col1 Col2))
    assert_equal([%w(Col1 Col2)], t.to_a)

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

  def test_extract
    t = TableTransform::Table.create_empty(%w(Name Age Length))
    t << {name: 'Joe',  age: 20, length: 170}
    t << {name: 'Jane', age: 45, length: 172}

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
    t_orig << {name: 'Joe',  age: 20, length: 170}
    t_orig << {name: 'Jane', age: 45, length: 172}
    t_orig << {name: 'Anna', age: 20, length: 165}

    t2 = t_orig.filter(:age, 20)
    assert_kind_of(TableTransform::Table, t2)
    assert_equal(3, t2.to_a.size, 'Header row + filtered rows')
    assert( not(t2.to_a.flatten.include? ('Jane')), 'Value should be filtered out')
    assert_equal('Anna', t2.to_a.last[0], 'Row order and type preserved')
    assert_equal(165,    t2.to_a.last[2], 'Row order and type preserved')

    t2 = t_orig.filter(:age, 70)
    assert_equal(1, t2.to_a.size, 'Header row only')

    # Chain filter and extract
    t2 = t_orig.filter(:age, 45).extract(%w(name))
    assert_kind_of(TableTransform::Table, t2)
    assert_equal(2, t2.to_a.size, 'Header row + filtered row')
    assert_equal(1, t2.to_a.last.size, 'Only one column')
    assert_equal('Jane', t2.to_a.last[0])

    # Columns must exist
    e = assert_raises{ t_orig.filter(:xxx, 20) }
    assert_equal("No column with name 'xxx' exists", e.to_s)
  end

  def test_op_plus
    #vanilla
    t1 = TableTransform::Table.create_empty(%w(Name Age Length))
    t1 << {name: 'Joe',  age: 20, length: 170}

    t2 = TableTransform::Table.create_empty(%w(Name Age Length))
    t2 << {name: 'Jane', age: 45, length: 172}

    assert_equal([%w(Name Age Length),
                  ['Joe', 20, 170],
                  ['Jane', 45, 172]],
                 (t1 + t2).to_a)

    #header mismatch
    t1 = TableTransform::Table.create_empty(%w(Name Age Length))
    t2 = TableTransform::Table.create_empty(%w(Name Length Age))
    e = assert_raises{ t1 + t2 }
    assert_equal('Tables cannot be added due to header mismatch', e.to_s)
  end

  def bench_extract
    # t = TableTransform::Table.create_empty(['Name', 'Age', 'Length'])
    # n = 100_000
    # n.times { t << {name: 'Joe',  age: 20, length: 170}}
    #
    # time = Benchmark.realtime { t.extract(['Name', 'Length']) }
    #
    # puts "Extract/sec: #{(n / time).to_i}"
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
    t << {name: 'Joe',  age: 20, length: 170}
    t << {name: 'Jane', age: 45, length: 172}

    result = t.delete_column('Age')
    assert_kind_of(TableTransform::Table, result, 'Self chaining')
    assert_equal([%w(Name Length),
                  ['Joe', 170],
                  ['Jane', 172]],
                 t.to_a)

    t2 = TableTransform::Table.create_empty(%w(Name Age Length Address))
    t2 << {name: 'Joe',  age: 20, length: 170, address:'home'}
    t2 << {name: 'Jane', age: 45, length: 172, address:'away'}
    t2.delete_column(:name, :address)
    assert_equal([%w(Age Length),
                  [20, 170],
                  [45, 172]],
                 t2.to_a)

    e = assert_raises{ t2.delete_column('xxx') }
    assert_equal("No column with name 'xxx' exists", e.to_s)
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
    t << {severity: :alarm, category: 'External'}
    assert_equal(2, t.to_a.count)
    assert_equal([:alarm, 'External'], t.to_a.last)

    # Vanilla insert reversed order
    t << {category: 'External', severity: :alarm}
    assert_equal(3, t.to_a.count)
    assert_equal([:alarm, 'External'], t.to_a.last)

    # default value of hash key is missing
    t << {severity: :warning}
    assert_equal(4, t.to_a.count)
    assert_equal([:warning, ''], t.to_a.last, "Default default value ''")

    # streamed values not in specified output columns will not be added
    t << {severity: :warning, dummy: 'DummyValue'}
    assert_equal(5, t.to_a.count)
    assert_equal([:warning, ''], t.to_a.last, "Default default value ''")

    # streaming can be chained
    t << {severity: :normal, category: 'T1'} << {severity: :normal, category: 'T2'}
    assert_equal(7, t.to_a.count)
    assert_equal([[:normal, 'T1'], [:normal, 'T2']], t.to_a[-2,2])

  end
end