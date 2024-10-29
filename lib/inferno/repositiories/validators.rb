require 'inferno/repositories/in_memory_repository'

module Inferno
  module Repositories
    class Validators < InMemoryRepository
      def insert(entity)
        raise Exceptions::DuplicateEntityUrlException, entity.url if exists?(entity.url)

        all << entity
        all_by_id[entity.url.to_s] = entity
        entity
      end

      def all_urls
        all_by_id.keys
      end
    end
  end
end
