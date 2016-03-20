require_relative 'test_helper'
require 'table_transform/properties'


class Validator
  def self.valid?(props)
  end
end

class PropertiesTest < Minitest::Test



  def test_create
    p = TableTransform::Properties.new
    assert_equal({}, p.to_h)

    p = TableTransform::Properties.new({key1: 'value1'})
    assert_equal({:key1 => 'value1'}, p.to_h)

    e = assert_raises{ TableTransform::Properties.new([]) }
    assert_equal('Default properties must be a hash', e.to_s)
  end

  def test_update
    p = TableTransform::Properties.new({key1: 'value1'})
    assert_equal({:key1 => 'value1'}, p.to_h)
    p.update({key1: 'value1b', key2: 'value2'})
    assert_equal({:key1 => 'value1b', :key2 => 'value2'}, p.to_h)

    # Update empty and nothing changes
    p = TableTransform::Properties.new({key1: 'value1'})
    p.update({})
    assert_equal({:key1 => 'value1'}, p.to_h)

    # Make sure properties are individual instances
    k3 = {key3: 'value3'}
    p1 = TableTransform::Properties.new(k3)
    p2 = TableTransform::Properties.new(k3)
    p1.update({key3: 'value3a'})
    assert_equal({:key3 => 'value3a'}, p1.to_h)
    assert_equal({:key3 => 'value3'}, p2.to_h)
  end

  def test_delete
    p = TableTransform::Properties.new({key1: 'value1', :key2 => 'value2'})
    p.delete(:key1)
    assert_equal({:key2 => 'value2'}, p.to_h)

    # Silently ignores non existing keys
    p = TableTransform::Properties.new({key1: 'value1'})
    p.delete(:xxx)
    assert_equal({:key1 => 'value1'}, p.to_h)
  end

  def test_reset
    p = TableTransform::Properties.new({key1: 'value1', :key2 => 'value2'})
    p.reset({key3: 'value3'})
    assert_equal({:key3 => 'value3'}, p.to_h)
  end

  def test_access_op
    p = TableTransform::Properties.new({key1: 'value1', :key2 => 2})
    assert_equal('value1', p[:key1])
    assert_equal(2, p[:key2])
    assert_equal(nil, p[:xxx])
  end

end
