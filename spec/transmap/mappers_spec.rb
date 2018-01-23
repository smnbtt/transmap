require 'spec_helper'
require 'active_support/all'


describe Transmap::Mappers do

  class self::ClassWithOneSimpleMap
    include Transmap::Mappers

    simple_map test_id: :externalTestId,
               another_test_id: :anotherExternalTestId

  end

  class self::ClassWithMultipleSimpleMap
    include Transmap::Mappers

    simple_map test_id: :externalTestId,
               another_test_id: :anotherExternalTestId

    simple_map second_test_id: :secondExternalTestId

  end

  class self::ClassWithOneTransformMap
    include Transmap::Mappers

    transform_map :test_id, :externalTestId,
                  to: :test_serialize, from: :test_deserialize

    def self.test_serialize(val)
      val
    end

    def self.test_deserialize(val)
      val
    end

  end

  class self::ClassWithMultipleTransformMap
    include Transmap::Mappers

    transform_map :test_id, :externalTestId,
                  to: :test_serialize, from: :test_deserialize

    transform_map :extra_test_id, :extraExternalTestId,
                  to: :test_serialize, from: :test_deserialize

    def self.test_serialize(val)
      val
    end

    def self.test_deserialize(val)
      val
    end

  end

  class self::ClassWithOneTransformMapNoMethod
    include Transmap::Mappers

    transform_map :test_id, :externalTestId,
                  to: :test_serialize, from: :test_deserialize

  end

  class self::ClassWithConflictMappings
    include Transmap::Mappers

    simple_map test_id: :externalTestId,
               another_test_id: :anotherExternalTestId

    transform_map :test_id, :externalTestId,
                  to: :test_serialize, from: :test_deserialize

    transform_map :transformed_test_id, :anotherExternalTestId,
                  to: :test_serialize, from: :test_deserialize

    def self.test_serialize(val)
      val - 1
    end

    def self.test_deserialize(val)
      val + 1
    end

  end

  class self::Window
    include Transmap::Mappers

    simple_map id: :windowId,
               is_exclusive: :exclusive,
               is_perpetual: :perpetual

    transform_map :start_on, :epochStart,
                  to: :datetime_to_epoch, from: :epoch_to_datetime
    transform_map :end_on, :epochEnd,
                  to: :datetime_to_epoch, from: :epoch_to_datetime


    def self.epoch_to_datetime(milliseconds)
      Time.at(milliseconds/1000).to_datetime if milliseconds.present?
    end

    def self.datetime_to_epoch(datetime)
      datetime.to_i * 1000 if datetime.present?
    end

  end

  context 'with one simple_map' do

    it 'should serialize from hash and deserialize' do

      test_hash = {
          externalTestId: 1,
          anotherExternalTestId: true,
      }
      test_instance = self.class::ClassWithOneSimpleMap.from_hash(test_hash)
      expect(test_instance.to_hash).to eq(test_hash)

    end

    it 'should ignore mapped keys without values' do

      test_hash = {
          externalTestId: 1,
      }
      test_instance = self.class::ClassWithOneSimpleMap.from_hash(test_hash)
      test_result = test_instance.to_hash
      expect(test_result).to eq({externalTestId: 1})

    end

    it 'should ignore undefined mapped keys' do

      test_hash = {
          externalTestId: 1,
          anotherExternalTestId: true,
          ignoredId: true,
      }

      test_instance = self.class::ClassWithOneSimpleMap.from_hash(test_hash)
      test_result = test_instance.to_hash
      expect(test_result).to eq(test_hash.slice(:externalTestId, :anotherExternalTestId))

    end

    it 'should expose mapped keys' do

      test_hash = {
          externalTestId: 1,
          anotherExternalTestId: true
      }

      test_instance = self.class::ClassWithOneSimpleMap.from_hash(test_hash)
      expect(test_instance.test_id).to eq(test_hash[:externalTestId])
      expect(test_instance.another_test_id).to eq(test_hash[:anotherExternalTestId])

    end

    it 'should send an event notification' do

      test_hash = {
          externalTestId: 1,
          anotherExternalTestId: true
      }


      events = []

      ActiveSupport::Notifications.subscribe('from_hash.mappers.transmap') do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end


      self.class::ClassWithOneSimpleMap.from_hash(test_hash)

      expect(events.first.name).to eq('from_hash.mappers.transmap')
      expect(events.first.payload).to eq(test_hash)

    end

  end


  context 'with multiple simple_map' do

    it 'should serialize from hash and deserialize' do

      test_hash = {
          externalTestId: 1,
          anotherExternalTestId: true,
          secondExternalTestId: 'test'

      }
      test_instance = self.class::ClassWithMultipleSimpleMap.from_hash(test_hash)
      expect(test_instance.to_hash).to eq(test_hash)

    end

  end

  context 'with one transform_map' do

    it 'should serialize from hash and deserialize' do
      test_hash = {
          externalTestId: 1,
      }
      test_instance = self.class::ClassWithOneTransformMap.from_hash(test_hash)
      expect(test_instance.to_hash).to eq(test_hash)
    end

    it 'should execute the class method defined as from: during deserialization' do
      test_hash = {
          externalTestId: 1,
      }
      expect(self.class::ClassWithOneTransformMap).to receive(:test_deserialize).with(1).once
      self.class::ClassWithOneTransformMap.from_hash(test_hash)

    end

    it 'should execute the class method defined as to: during serialization' do
      test_hash = {
          externalTestId: 1,
      }
      expect(self.class::ClassWithOneTransformMap).to receive(:test_serialize).with(1).once
      self.class::ClassWithOneTransformMap.from_hash(test_hash).to_hash

    end

    it 'should throw an error if the deserialization method is missing' do
      test_hash = {
          externalTestId: 1,
      }

      expect {self.class::ClassWithOneTransformMapNoMethod.from_hash(test_hash)}.to raise_error(NoMethodError)

    end

  end

  context 'with multiple transform_map' do

    it 'should serialize from hash and deserialize' do

      test_hash = {
          externalTestId: 1,
          extraExternalTestId: true,

      }
      test_instance = self.class::ClassWithMultipleTransformMap.from_hash(test_hash)
      expect(test_instance.to_hash).to eq(test_hash)

    end

  end

  context 'with conflicting mappings' do

    it 'should serialize from hash and deserialize by using transformations' do

      test_hash = {
          externalTestId: 1,
          anotherExternalTestId: 4,
      }
      test_instance = self.class::ClassWithConflictMappings.from_hash(test_hash)
      expect(test_instance.test_id).to eq(self.class::ClassWithConflictMappings.test_deserialize(1))
      expect(test_instance.another_test_id).to eq(4)
      expect(test_instance.transformed_test_id).to eq(self.class::ClassWithConflictMappings.test_deserialize(4))
      expect(test_instance.to_hash).to eq(test_hash)

    end
  end

  context 'with full example Window class' do
    it 'should serialize from hash and deserialize' do

      test_hash = {
          windowId: 1,
          exclusive: true,
          perpetual: false,
          epochStart: 1516499650000,
          epochEnd: 1516599650000
      }
      window = self.class::Window.from_hash(test_hash)

      expect(window).to be_a_kind_of(Transmap::Mappers)
      expect(window.to_hash).to eq(test_hash)

    end

  end
end