require 'minitest/autorun'
require 'tabletransform/store'

class StoreTest < Minitest::Test
  def test_default
    s = Store.new
    assert_equal(1, s.to_a.count, 'Only header')

    s << {severity: :alarm, category: 'External'}
    assert_equal(2, s.to_a.count)
    assert_equal(%w(Alarm External), s.to_a.last[0..1])

    s << {severity: :warning}
    assert_equal(3, s.to_a.count)
    assert_equal(%w(Warning Internal), s.to_a.last[0..1], 'Default category test')
  end

  def test_partition
    s = Store.new
    s << {severity: :alarm, category: 'External', partition: :ext}
    s << {severity: :alarm, category: 'External'}
    assert_equal(3, s.to_a.count)

    assert_equal(2, s.partition.count,     'Header and row')
    assert_equal(2, s.partition(:ext).count, 'Header and row')
  end
end