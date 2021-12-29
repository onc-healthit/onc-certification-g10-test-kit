require 'inferno/repositories/in_memory_repository'

module Inferno
  module Repositories
    class Validators < InMemoryRepository
      def self.index_by_id
        @all_by_id = {}
        all.each { |vs| @all_by_id[vs.url] = vs }
        @all_by_id
      end

      def all_urls
        all_by_id.keys
      end
    end
  end
end
