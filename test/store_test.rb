require 'benchmark'
require 'minitest/autorun'
require 'tabletransform/store'

class StoreTest < Minitest::Test
  def test_default
    s = Store.new(%w(Severity Category))
    assert_equal(1, s.to_a.count, 'Only header')
    assert_equal(%w(Severity Category), s.to_a.first)

    # Vanilla insert
    s << {severity: :alarm, category: 'External'}
    assert_equal(2, s.to_a.count)
    assert_equal([:alarm, 'External'], s.to_a.last)

    # Vanilla insert reversed order
    s << {category: 'External', severity: :alarm}
    assert_equal(3, s.to_a.count)
    assert_equal([:alarm, 'External'], s.to_a.last)

    # default value of hash key is missing
    s << {severity: :warning}
    assert_equal(4, s.to_a.count)
    assert_equal([:warning, ''], s.to_a.last, "Default default value ''")

    # streamed values not in specified output columns will not be added
    s << {severity: :warning, dummy: 'DummyValue'}
    assert_equal(5, s.to_a.count)
    assert_equal([:warning, ''], s.to_a.last, "Default default value ''")

    # streaming can be chained
    s << {severity: :normal, category: 'T1'} << {severity: :normal, category: 'T2'}
    assert_equal(7, s.to_a.count)
    assert_equal([[:normal, 'T1'], [:normal, 'T2']], s.to_a[-2,2])
  end

  def test_partition
    s = Store.new(%w(Severity Category), :partition)
    s << {severity: :alarm, category: 'External', partition: :ext}
    s << {severity: :alarm, category: 'External'}
    assert_equal(3, s.to_a.count,            'Header and all rows')
    assert_equal(2, s.partition.count,       'Header and row')
    assert_equal(2, s.partition(:ext).count, 'Header and row')
    assert_equal(1, s.partition(:unknown).count, 'Header only')
  end

  def test_performance
    s = Store.new(%w(Severity Category A B C D E F))
    data = {severity: :alarm, category: 'External'}
    data = {}
    n = 500_000
    time = Benchmark.realtime {
      n.times do
        s << data
      end
    }

    puts n / time

  end
end

