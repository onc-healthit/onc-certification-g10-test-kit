module Inferno
  module Terminology
    module Tasks
      class CountCodesInValueSet
        attr_reader :value_set_url

        def initialize(vs:) # rubocop:disable Naming/MethodParameterName
          @value_set_url = vs
        end

        def run
          Loader.register_umls_db File.join(TEMP_DIR, 'umls.db')
          Loader.load_value_sets_from_directory(PACKAGE_DIR, true)
          vs = Repositories::ValueSets.new.find(value_set_url)
          Inferno.logger.info vs&.valueset&.count
        end
      end
    end
  end
end
