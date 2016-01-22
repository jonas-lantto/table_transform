require 'minitest/autorun'
require 'tabletransform/store'

class StoreTest < Minitest::Test
  def test_default
    s = Store.new(%w(Severity Category))
    assert_equal(1, s.to_a.count, 'Only header')
    assert_equal(%w(Severity Category), s.to_a.first)

    s << {severity: :alarm, category: 'External'}
    assert_equal(2, s.to_a.count)
    assert_equal([:alarm, 'External'], s.to_a.last)

    s << {severity: :warning}
    assert_equal(3, s.to_a.count)
    assert_equal([:warning, ''], s.to_a.last, "Default default value ''")
  end

  def test_column_filtering
    s = Store.new(%w(Category Severity))
    assert_equal(1, s.to_a.count, 'Only header')
    assert_equal(%w(Category Severity), s.to_a.first)

    s << {severity: :alarm, category: 'External'}
    assert_equal(2, s.to_a.count)
    assert_equal(['External', :alarm], s.to_a.last)

    s << {severity: :warning, dummy: 'DummyValue'}
    assert_equal(3, s.to_a.count)
    assert_equal(['', :warning], s.to_a.last, "Default default value ''")
  end


  def test_partition
    s = Store.new(%w(Severity Category))
    s << {severity: :alarm, category: 'External', partition: :ext}
    s << {severity: :alarm, category: 'External'}
    assert_equal(3, s.to_a.count)

    assert_equal(2, s.partition.count,     'Header and row')
    assert_equal(2, s.partition(:ext).count, 'Header and row')
  end
end