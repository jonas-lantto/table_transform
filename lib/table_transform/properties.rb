require 'forwardable'

module TableTransform

  class Properties
    extend Forwardable
    def_delegators :@props, :delete, :each, :[], :[]=

    def initialize(init_properties = {})
      validate(init_properties)
      @props = init_properties
    end

    def validate(properties)
      raise 'Default properties must be a hash' unless properties.is_a? Hash
    end

    def to_h
      @props.clone
    end

    def update(properties)
      validate(properties)
      @props.merge! properties
    end

    def reset(properties)
      validate(properties)
      @props = properties
    end

  end

  class MultiProperties
    extend Forwardable
    def_delegators :@multi_props, :delete, :each, :keys, :size

    def initialize(klass, init_properties = {})
      k = klass.new(init_properties) # force validation in klass to run
      @klass = klass
      #@multi_props = Hash.new{|hash, key| hash[key] = klass.new(init_properties.dup)}
      @multi_props = Hash.new{|hash, key| raise "No column with name '#{key}' exists"}
    end

    def create(*keys, properties)
      keys.each{|k| @multi_props.store(k, @klass.new(properties))}
    end

    def to_h
      #@multi_props.clone.to_h
      res = Hash.new
      @multi_props.each{|k, v|
        res << {k => v.to_h}
      }
      p res
      res
    end

    def update(*keys, properties)
      keys.each{|k| @multi_props[k].update(properties)}
    end

    def reset(*keys, properties)
      keys.each{|k|
        #@multi_props.store(k, @klass.new(properties)) unless @multi_props.include? k
        @multi_props[k].reset(properties)
      }
    end

    def rename_key(from, to)
      @multi_props = @multi_props.map{|k,v| [k == from ? to : k, v] }.to_h
    end

    def [](key)
      return nil unless @multi_props.include? key
      @multi_props[key].to_h
    end

    def ==(multi_props)
      return false unless @multi_props.keys == multi_props.keys
      @multi_props.each{|k, v| return false unless v.to_h == multi_props[k].to_h }
      true
    end
  end
end
