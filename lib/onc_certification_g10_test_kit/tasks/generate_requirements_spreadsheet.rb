require 'rubyXL'
require 'rubyXL/convenience_methods'
require_relative 'test_procedure'

module ONCCertificationG10TestKit
  module Tasks
    class GenerateRequirementsSpreadsheet
      attr_accessor :row

      TEST_PROCEDURE_URL = 'https://www.healthit.gov/test-method/standardized-api-patient-and-population-services#test_procedure'.freeze
      FILE_NAME = File.join('lib', 'onc_certification_g10_test_kit', 'requirements',
                            '(g)(10)-test-procedure_requirements.xlsx')

      def inferno_to_procedure_map
        @inferno_to_procedure_map ||= Hash.new { |h, k| h[k] = [] }
      end

      def test_procedure
        @test_procedure ||=
          if File.file? File.join('lib', 'onc_certification_g10_test_kit', 'onc_program_procedure.yml')
            TestProcedure.new(
              YAML.load_file(File.join('lib', 'onc_certification_g10_test_kit',
                                       'onc_program_procedure.yml')).deep_symbolize_keys
            )
          else
            TestProcedure.new
          end
      end

      def test_suite
        ONCCertificationG10TestKit::G10CertificationSuite
      end

      def workbook
        @workbook ||= RubyXL::Parser.parse(FILE_NAME)
      end

      def next_row
        self.row += 1
      end

      def run
        clear_requirements_worksheet
        add_test_procedure_requirements

        Inferno.logger.info "Writing to #{FILE_NAME}"
        workbook.write(FILE_NAME)
      end

      def clear_requirements_worksheet
        requirements_worksheet = workbook['Requirements']
        requirements_worksheet.sheet_data[1]
        requirements_worksheet.delete_row(1) until requirements_worksheet.cell_at('A2').nil?
      end

      def add_test_procedure_requirements # rubocop:disable Metrics/CyclomaticComplexity
        requirements_worksheet = workbook['Requirements']
        self.row = 0

        test_procedure.sections.each do |section|
          section.steps.group_by(&:group).each_value do |steps|
            steps.each do |step|
              next_row

              lines = step.s_u_t&.lines&.count || 0
              requirements_worksheet.change_row_height(row, (lines * 16) + 10)
              requirements_worksheet.change_row_vertical_alignment(row, 'top')

              requirements_worksheet.add_cell(row, 0, "#{step.id.upcase} ")
              requirements_worksheet.add_cell(row, 1, TEST_PROCEDURE_URL)
              requirements_worksheet.add_cell(row, 2, step.s_u_t).change_text_wrap(true)
              requirements_worksheet.add_cell(row, 3, 'SHALL')
              requirements_worksheet.add_cell(row, 4, 'Server')
              requirements_worksheet.add_cell(row, 5, '')
              requirements_worksheet.add_cell(row, 6, 'FALSE')
            end
          end
        end
      end
    end
  end
end
