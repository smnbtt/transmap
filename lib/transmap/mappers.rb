module Transmap

  # Includes the required interface for an object serialize and deserialize data
  module Mappers

    # Class methods exposed
    module ClassMethods

      # Define simple mappings,
      # the class will be able deserialize and serialize hashes by using the key pairs
      # @example How to use simple_map in a normal class
      #   class TestClass
      #     include Transmap::Mappers
      #     simple_map key: :external_key, second_key: :second_external_key
      #   end
      #
      # @param mappings [Hash] key values pairs of mappings
      # @return [Hash] current simple mappings
      def simple_map(mappings)
        if @simple_mappings
          @simple_mappings.merge!(mappings)
        else
          @simple_mappings = mappings
        end
        mappings.keys.each {|internal_key| define_accessor_methods(internal_key)}
        simple_mappings
      end

      # Define a transformation mapping,
      # the class will deserialize and serialize hashes by using the define class methods in to: and from:
      # @example How to use transform_map in a normal class
      #   class TestClass
      #     include Transmap::Mappers
      #     transform_map :key, :external_key, to: :serialization_method, from: :deserialization_method
      #   end
      #
      # @param id [Symbol] internal key
      # @param source [Symbol] external key
      # @param to [Symbol] serialization method
      # @param from [Symbol] deserialization method
      # @return [Hash] current transform mappings
      def transform_map(id, source, to:, from:)
        # @NOTE To keep the module simple I used hash of hashes as data structure to keep the mapping references
        #   normally I will try to use an object but it seemed overkill in this case.
        #   Also, we need to keep track of keys anyway with an hash, so any performance gain by using objects is
        #   going to be minimal.
        if @transform_mappings
          @transform_mappings.merge!(
              {
                  id => {
                      source: source,
                      to: to,
                      from: from
                  }
              }
          )
        else
          @transform_mappings = {
              id => {
                  source: source,
                  to: to,
                  from: from
              }
          }
        end
        define_accessor_methods(id)
        transform_mappings
      end

      # @return [Hash] current simple mappings
      def simple_mappings
        @simple_mappings || {}
      end

      # @return [Hash] current transform mappings
      def transform_mappings
        @transform_mappings || {}
      end

      # Deserialize an hash into the current Class object
      # @param hash [Hash] hash with key values pairs to deserialize
      # @return [Object] instance of the Class with deserialized data
      def from_hash(hash)
        ActiveSupport::Notifications.instrument('from_hash.mappers.transmap', hash) do
          self.new(deserialize_from_hash(hash))
        end
      end

      private

      # create accessor methods for a specific internal_key binding
      # @example How to use simple_map in a normal class
      #   class TestClass
      #     include Transmap::Mappers
      #     simple_map key: :external_key, second_key: :second_external_key
      #   end
      #
      #   test_class = TestClass.new
      #   test_class.key = 1
      #   test_class.key # -> 1
      # @param internal_key [Symbol] accessor key
      def define_accessor_methods(internal_key)

        define_method(internal_key.to_sym) do
          instance_variable_get("@#{internal_key.to_sym}")
        end

        define_method("#{internal_key.to_sym}=") do |value|
          instance_variable_set("@#{internal_key.to_sym}", value)
        end

      end

      # Deserialize from hash
      # @param hash [Hash] key values to deserialize
      # @return [Hash] deserialize the object from the original mapping keys and values
      def deserialize_from_hash(hash)
        # @NOTE Inverting mappings once so we can easily iterate over the hash and execute the deserialization
        inverted_simple_mappings = self.simple_mappings.invert
        inverted_transform_mappings = self.transform_mappings.map do |internal_key, mapping|
          [mapping[:source], {
              internal_key: internal_key,
              method: mapping[:from]
          }]
        end.to_h

        hash.each_with_object({}) do |(external_key, val), obj|
          internal_key = inverted_simple_mappings[external_key]
          transformation = inverted_transform_mappings[external_key]

          # @NOTE I'm assuming any key not defined in the mappings will be just ignored, A service could
          #  always add a new attribute in their object schema and our deserializer should not break during ingestion
          obj[internal_key] = val if internal_key

          # @NOTE if a transformation is defined for an external_key sharing the same internal_key, we overwrite the simple_mappings
          if transformation
            internal_key = transformation[:internal_key]
            # @NOTE I didn't catch if self.class.send fails because by default ruby throws NoMethodError that is pretty clear
            val = self.send(transformation[:method], val)
            obj[internal_key] = val
          end
        end
      end

    end

    # serialize the object using the original mapping keys and values
    # @return [Hash] serialize the object in hash
    def to_hash
      simple = self.class.simple_mappings.map do |internal_key, external_key|
        [external_key, instance_variable_get("@#{internal_key}")]
      end.to_h

      # @NOTE I didn't catch if self.class.send fails because by default ruby throws NoMethodError that is pretty clear
      transformed = self.class.transform_mappings.map do |internal_key, mapping|
        [mapping[:source], self.class.send(mapping[:to], instance_variable_get("@#{internal_key}"))]
      end.to_h

      # @NOTE I'm assuming any empty key will not serialize and
      #   overwrite simple_mappings with transform_mappings if they share the same key
      simple.merge(transformed).compact
    end

    # @param attributes [Hash] attributes to instantiate as instance variables
    def initialize(attributes = {})
      initialize_attributes(attributes) if attributes
      super()
    end

    # @param attributes [Hash] attributes to instantiate as instance variables
    def initialize_attributes(attributes)
      attributes.each do |internal_key, value|
        instance_variable_set("@#{internal_key}", value)
      end
    end

    # Module included hook
    # @param receiver [Class] class including the module
    def self.included(receiver)
      receiver.extend ClassMethods
      # Auto subscribe to from_hash events with EventLogger
      ActiveSupport::Notifications.subscribe('from_hash.mappers.transmap', EventLogger.new)
    end

  end
end