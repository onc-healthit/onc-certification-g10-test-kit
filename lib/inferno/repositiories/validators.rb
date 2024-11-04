require 'inferno/repositories/in_memory_repository'

module Inferno
  module Repositories
    class Validators < InMemoryRepository
      def all_urls
        all_by_id.keys
      end
    end
  end
end
