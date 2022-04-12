require 'rubyXL'
require 'rubyXL/convenience_methods'
require 'inferno'
require_relative '../../onc_certification_g10_test_kit'
require_relative 'test_procedure'

module ONCCertificationG10TestKit
  module Tasks
    class GenerateMatrix
      include ONCCertificationG10TestKit

      FILE_NAME = 'onc_certification_g10_matrix.xlsx'.freeze

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
        @workbook ||= RubyXL::Workbook.new
      end

      def run
        generate_matrix_worksheet
        generate_test_procedure_worksheet
        generate_inferno_test_worksheet

        Inferno.logger.info "Writing to #{FILE_NAME}"
        workbook.write(FILE_NAME)
      end

      def generate_matrix_worksheet # rubocop:disable Metrics/CyclomaticComplexity
        matrix_worksheet = workbook.worksheets[0]
        matrix_worksheet.sheet_name = 'Matrix'

        col = 2
        matrix_worksheet.add_cell(0, 1, "ONC Certification (g)(10) Test Kit (v#{ONCCertificationG10TestKit::VERSION})")
        matrix_worksheet.change_row_height(0, 20)
        matrix_worksheet.change_row_vertical_alignment(0, 'distributed')
        column_map = {}
        matrix_worksheet.change_column_width(1, 25)
        matrix_worksheet.change_row_height(1, 20)
        matrix_worksheet.change_row_horizontal_alignment(1, 'center')
        matrix_worksheet.change_row_vertical_alignment(1, 'distributed')
        matrix_worksheet.change_row_height(2, 70)
        column_borders = []

        test_suite.groups.each do |group|
          matrix_worksheet.add_cell(1, col, group.title).change_text_wrap(true)
          matrix_worksheet.merge_cells(1, col, 1, col + group.groups.length - 1)
          matrix_worksheet.change_column_border(col, :left, 'medium')
          matrix_worksheet.change_column_border_color(col, :left, '000000')
          column_borders << col

          group.groups.each do |test_case|
            matrix_worksheet.change_column_width(col, 4.2)

            cell = matrix_worksheet.add_cell(2, col,
                                             "#{test_case.short_id} #{test_case.short_title || test_case.title}")
            cell.change_text_rotation(90)
            cell.change_border_color(:bottom, '000000')
            cell.change_border(:bottom, 'medium')
            matrix_worksheet.change_column_border(col, :right, 'thin')
            matrix_worksheet.change_column_border_color(col, :right, '666666')

            test_case.tests.each do |test|
              # tests << { test_case: test_case, test: test }
              # full_test_id = "#{test_case.prefix}#{test.id}"
              column_map[test.short_id] = col
            end
            col += 1
          end
        end

        total_width = col - 1
        matrix_worksheet.merge_cells(0, 1, 0, total_width)
        matrix_worksheet.change_row_horizontal_alignment(0, 'center')

        matrix_worksheet.add_cell(2, total_width + 2, 'Supported?')
        row = 3

        test_procedure.sections.each do |section|
          section.steps.each do |step|
            step_id = step.id.upcase
            matrix_worksheet.add_cell(row, 1, "#{step_id} ")
            matrix_worksheet.change_row_height(row, 13)
            matrix_worksheet.change_row_vertical_alignment(row, 'distributed')

            (2..total_width).each do |column|
              matrix_worksheet.add_cell(row, column, '')
            end

            step.inferno_tests.each do |test_id|
              column = column_map[test_id]
              inferno_to_procedure_map[test_id].push(step_id)
              if column.nil?
                puts "No such test found: #{test_id}"
                next
              end

              matrix_worksheet.add_cell(row, column, '').change_fill('3C63FF')
            end

            matrix_worksheet.add_cell(row, total_width + 2, step.inferno_supported.upcase)

            row += 1
          end
        end
        matrix_worksheet.change_column_horizontal_alignment(1, 'right')
        matrix_worksheet.change_row_horizontal_alignment(0, 'center')

        column_borders.each do |column|
          matrix_worksheet.change_column_border(column, :left, 'medium')
          matrix_worksheet.change_column_border_color(column, :left, '000000')
        end
        matrix_worksheet.change_column_border_color(total_width, :right, '000000')
        matrix_worksheet.change_column_border(total_width, :right, 'medium')
        matrix_worksheet.change_column_width(total_width + 1, 3)

        matrix_worksheet.change_column_width(total_width + 3, 6)
        matrix_worksheet.change_column_width(total_width + 4, 2)
        matrix_worksheet.change_column_width(total_width + 5, 60)
        matrix_worksheet.add_cell(1, total_width + 3, '').change_fill('3C63FF')
        this_text = 'Blue boxes indicate that the Inferno test (top) covers this test procedure step (left).'
        matrix_worksheet.add_cell(1, total_width + 5, this_text).change_text_wrap(true)
        matrix_worksheet.change_column_horizontal_alignment(total_width + 5, :left)
      end

      def generate_test_procedure_worksheet # rubocop:disable Metrics/CyclomaticComplexity
        workbook.add_worksheet('Test Procedure')
        tp_worksheet = workbook.worksheets[1]

        [3, 3, 22, 65, 65, 3, 15, 30, 65, 65].each_with_index do |width, index|
          tp_worksheet.change_column_width(index, width)
        end
        ['',
         '',
         'ID',
         'System Under Test',
         'Test Lab Verifies',
         '',
         'Inferno Supports?',
         'Inferno Tests',
         'Inferno Notes',
         'Alternate Test Methodology'].each_with_index { |text, index| tp_worksheet.add_cell(0, index, text) }

        row = 2

        test_procedure.sections.each do |section|
          tp_worksheet.add_cell(row, 0, section.name)
          row += 1
          section.steps.group_by(&:group).each do |group_name, steps|
            tp_worksheet.add_cell(row, 1, group_name)
            row += 1
            steps.each do |step|
              longest_line = [step.s_u_t, step.t_l_v, step.inferno_notes, step.alternate_test].map do |text|
                text&.lines&.count || 0
              end.max
              tp_worksheet.change_row_height(row, (longest_line * 10) + 10)
              tp_worksheet.change_row_vertical_alignment(row, 'top')
              tp_worksheet.add_cell(row, 2, "#{step.id.upcase} ")
              tp_worksheet.add_cell(row, 3, step.s_u_t).change_text_wrap(true)
              tp_worksheet.add_cell(row, 4, step.t_l_v).change_text_wrap(true)
              tp_worksheet.add_cell(row, 5, '')
              tp_worksheet.add_cell(row, 6, step.inferno_supported)
              tp_worksheet.add_cell(row, 7, step.inferno_tests.join(', ')).change_text_wrap(true)
              tp_worksheet.add_cell(row, 8, step.inferno_notes).change_text_wrap(true)
              tp_worksheet.add_cell(row, 9, step.alternate_test).change_text_wrap(true)
              row += 1
            end
          end
          row += 1
        end
      end

      def generate_inferno_test_worksheet # rubocop:disable Metrics/CyclomaticComplexity
        workbook.add_worksheet('Inferno Tests')
        inferno_worksheet = workbook.worksheets[2]

        columns = [
          ['', 3, ->(_test) { '' }],
          ['', 3, ->(_test) { '' }],
          ['Inferno Test ID', 22, ->(test) { test.short_id.to_s }],
          ['Inferno Test Name', 65, ->(test) { test.title }],
          ['Inferno Test Description', 65, lambda do |test|
            description = test.description || ''
            natural_indent =
              description
                .lines
                .collect { |l| l.index(/[^ ]/) }
                .select { |l| !l.nil? && l.positive? }
                .min || 0
            description.lines.map { |l| l[natural_indent..] || "\n" }.join.strip
          end],
          ['Test Procedure Steps', 30, ->(test) { inferno_to_procedure_map[test.short_id].join(', ') }]
        ]

        columns.each_with_index do |row_name, index|
          inferno_worksheet.add_cell(0, index, row_name.first)
        end

        row = 1

        test_suite.groups.each do |group|
          row += 1
          inferno_worksheet.add_cell(row, 0, group.title)
          row += 1
          group.groups.each do |test_case|
            inferno_worksheet.add_cell(row, 1, "#{test_case.short_id}: #{test_case.title}")
            row += 1
            test_case.tests.each do |test|
              this_row = columns.map do |column|
                column[2].call(test)
              end

              this_row.each_with_index do |value, index|
                inferno_worksheet.add_cell(row, index, value).change_text_wrap(true)
              end
              inferno_worksheet.change_row_height(row, [26, ((test.description || '').strip.lines.count * 10) + 10].max)
              inferno_worksheet.change_row_vertical_alignment(row, 'top')
              row += 1
            end
          end
        end

        columns.each_with_index do |column, index|
          inferno_worksheet.change_column_width(index, column[1])
        end
      end
    end
  end
end
