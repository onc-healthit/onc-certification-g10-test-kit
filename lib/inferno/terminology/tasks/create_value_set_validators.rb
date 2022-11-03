require_relative 'temp_dir'

module Inferno
  module Terminology
    module Tasks
      class CreateValueSetValidators
        include TempDir

        attr_reader :minimum_binding_strength, :version, :delete_existing, :type

        def initialize(minimum_binding_strength:, version:, delete_existing:, type:)
          @minimum_binding_strength = minimum_binding_strength
          @version = version
          @delete_existing = delete_existing != 'false'
          @type = type.to_sym
        end

        def run
          Loader.register_umls_db db_for_version
          Loader.load_value_sets_from_directory(PACKAGE_DIR, true)
          Loader.create_validators(
            type:,
            minimum_binding_strength:,
            delete_existing:
          )
        end

        def db_for_version
          File.join(versioned_temp_dir, 'umls.db')
        end
      end
    end
  end
end
