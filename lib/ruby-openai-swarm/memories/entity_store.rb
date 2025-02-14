module OpenAISwarm
  module Memories
    class EntityStore
      attr_accessor :entity_store,
                    :data

      def initialize(entity_store = nil)
        @entity_store = entity_store
        @data = entity_store&.data || {}
      end

      def entity_store_save
        return unless entity_store.respond_to?(:update)

        entity_store.update(data: data)
      end

      def add_entities(entities)
        entities.each { |key, value| @data[key.to_sym] = value }
        entity_store_save
      end

      def memories
        data&.to_json
      end

      # def add(key, value)
      #   @data[key] = value
      #    entity_store_save
      #   @data
      # end

      # def get(key)
      #   @data[key]
      # end

      # def exists?(key)
      #   @data.key?(key)
      # end

      # def remove(key)
      #   @data.delete(key)
      # end

      # def clear
      #   @data = {}
      # end

      # def all
      #   @data
      # end
    end
  end
end
