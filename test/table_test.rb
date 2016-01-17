require 'minitest/autorun'
require 'tabletransform/table'
#require 'tabletransform/table_extension'

class TableTest < Minitest::Test
#  using StaticMongChecker::TableExtension

  def test_table
    data = [
        ['Name',  'Age'],
        ['Jane',  '22'],
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

  def test_add_column
    data = [
        ['Name',  'Age'],
        ['Jane',  '22'],
        ['Joe',   nil]
    ]
    t = TableTransform::Table.new(data)

    result = t.add_column('NameLength'){|row| row['Name'].size}
    assert_kind_of(TableTransform::Table, result)
    assert_equal('NameLength', t.to_a[0][2])
    assert_equal(4, t.to_a[1][2])

    t.each_row{|r| assert_equal(r['Name'].size, r['NameLength'].to_i)}
  end

  def test_change_column
    data = [
        ['Name',  'Age'],
        ['Jane',  '22'],
        ['Joe',   nil]
    ]
    t = TableTransform::Table.new(data)
    result = t.change_column('Age'){|row| row['Age'].to_i * 2 unless row['Age'].empty?}
    assert_kind_of(TableTransform::Table, result)

    assert_equal('Age', t.to_a[0][1])
    assert_equal(22 * 2, t.to_a[1][1])

    ages = Array.new
    t.each_row{|r| ages << r['Age']}
    assert_equal([(22 * 2).to_s, ''], ages)

    e = assert_raises{ t.change_column('xxx'){|x| 'xxx'} }
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
end