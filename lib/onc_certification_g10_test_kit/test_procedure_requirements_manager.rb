require_relative 'tasks/test_procedure'

module ONCCertificationG10TestKit
  # @private
  # This module ensures that short test ids don't change
  module TestProcedureRequirementsManager
    class << self
      def all_children(runnable)
        runnable
          .children
          .flat_map { |child| [child] + all_children(child) }
      end

      def short_id_file_path
        File.join(__dir__, 'short_id_map.yml')
      end

      def short_id_map
        @short_id_map ||= YAML.load_file(short_id_file_path)
      end

      def assign_test_procedure_requirements
        all_children(G10CertificationSuite).each do |runnable|
          short_id = get_short_id(runnable)
          test_procedure_requirements = current_procedure_requirements_map[short_id]
          if test_procedure_requirements.present?
            current_requirements = runnable.verifies_requirements
            new_requirements = test_procedure_requirements.map do |req|
              "170.315(g)(10)-test-procedure_1.4@#{req}"
            end
            updated_requirements = current_requirements + new_requirements
            runnable.verifies_requirements(*updated_requirements)
          end
        rescue KeyError
          Inferno::Application['logger'].warn(
            "No test procedure map defined for id #{short_id} (from runnable #{runnable.id})"
          )
        end
      rescue Errno::ENOENT
        Inferno::Application['logger'].warn('No short id map found')
      end

      def get_short_id(runnable)
        short_id_map.fetch(runnable.id)
      rescue KeyError
        Inferno::Application['logger'].warn("No short id defined for #{runnable.id}")
      end

      def current_procedure_requirements_map
        @current_procedure_requirements_map ||=
          all_children(G10CertificationSuite).each_with_object({}) do |runnable, hash|
            short_id = get_short_id(runnable)
            test_procedure_requirement_list = requirements_for_short_id(short_id)
            next unless test_procedure_requirement_list.present?

            hash[short_id] = test_procedure_requirement_list
          end
      end

      def requirements_for_short_id(short_id)
        test_procedure_definition.sections.each_with_object([]) do |section, requirement_list|
          section.steps.each do |step|
            next unless step.inferno_tests.include?(short_id)

            requirement_list << step.id
          end
        end
      end

      def test_procedure_definition
        @test_procedure_definition ||=
          Tasks::TestProcedure.new(
            YAML.load_file(
              File.join(
                __dir__,
                'onc_program_procedure.yml'
              )
            ).deep_symbolize_keys
          )
      end
    end
  end
end
