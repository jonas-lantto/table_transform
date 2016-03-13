
module TableTransform

  class Properties
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

    def delete(prop_key)
      @props.delete(prop_key)
    end

    def reset(properties)
      validate(properties)
      @props = properties
    end

    def [](prop_key)
      raise "Property '#{prop_key}' does not exist" unless @props.include? prop_key
      @props[prop_key]
    end
  end
end
