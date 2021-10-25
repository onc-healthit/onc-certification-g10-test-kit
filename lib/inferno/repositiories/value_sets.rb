require 'inferno/repositories/in_memory_repository'

module Inferno
  module Repositories
    class ValueSets < InMemoryRepository
      def self.index_by_id
        @all_by_id = {}
        all.each { |vs| @all_by_id[vs.url] = vs }
        @all_by_id
      end

      # @return [Hash] a Hash where the keys are vs urls and the values are vs
      def select_by_url(urls)
        self.class.all_by_id.slice(*urls)
      end

      def select_by_binding_strength(strengths)
        all.select { |vs| strengths.include?(vs.strength) }
      end

      def find(url)
        super || raise(UnknownValueSetException, url)
      end
    end
  end
end
