require 'forwardable'

module TableTransform

  class Properties
    extend Forwardable
    def_delegators :@props, :delete, :each, :[]

    def initialize(init_properties = {})
      validate(init_properties)
      @props = init_properties.clone
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

end
