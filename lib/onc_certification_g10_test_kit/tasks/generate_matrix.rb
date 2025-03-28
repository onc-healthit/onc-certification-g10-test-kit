require 'rubyXL'
require 'rubyXL/convenience_methods'
require 'inferno'
require_relative '../../onc_certification_g10_test_kit'
require_relative 'test_procedure'

module ONCCertificationG10TestKit
  module Tasks
    class GenerateMatrix
      include ONCCertificationG10TestKit

      attr_accessor :row

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

      def next_row
        self.row += 1
      end

      def run
        generate_matrix_worksheet
        generate_test_procedure_worksheet
        generate_inferno_test_worksheet

        Inferno.logger.info "Writing to #{FILE_NAME}"
        workbook.write(FILE_NAME)
      end

      def all_descendant_tests(runnable)
        runnable.tests + runnable.groups.flat_map { |group| all_descendant_tests(group) }
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
          next if group.short_id == '6' # Skip US Core 5

          matrix_worksheet.add_cell(1, col, group.title).change_text_wrap(true)
          matrix_worksheet.merge_cells(1, col, 1, col + group.groups.length - 1) if group.groups.length.positive?
          matrix_worksheet.change_column_border(col, :left, 'medium')
          matrix_worksheet.change_column_border_color(col, :left, '000000')
          column_borders << col

          group.tests.each do |test|
            column_map[test.short_id] = col
          end

          group.groups.each do |test_case|
            matrix_worksheet.change_column_width(col, 4.2)

            cell = matrix_worksheet.add_cell(2, col,
                                             "#{test_case.short_id} #{test_case.short_title || test_case.title}")
            cell.change_text_rotation(90)
            cell.change_border_color(:bottom, '000000')
            cell.change_border(:bottom, 'medium')
            matrix_worksheet.change_column_border(col, :right, 'thin')
            matrix_worksheet.change_column_border_color(col, :right, '666666')

            all_descendant_tests(test_case).each { |test| column_map[test.short_id] = col }
            col += 1
          end
        end

        total_width = col - 1
        matrix_worksheet.merge_cells(0, 1, 0, total_width)
        matrix_worksheet.change_row_horizontal_alignment(0, 'center')

        matrix_worksheet.add_cell(2, total_width + 2, 'Supported?')
        self.row = 3

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

            next_row
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

        self.row = 2

        test_procedure.sections.each do |section|
          tp_worksheet.add_cell(row, 0, section.name)
          next_row
          section.steps.group_by(&:group).each do |group_name, steps|
            tp_worksheet.add_cell(row, 1, group_name)
            next_row
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
              next_row
            end
          end
          next_row
        end
      end

      # returns an array of options that apply to this test or group
      def applicable_options(runnable)
        runnable_and_parents = [runnable].tap do |parents|
          parents << parents.last.parent while parents.last.parent.present?
        end
        runnable_and_parents.map(&:suite_option_requirements).compact.flatten
      end

      def inferno_worksheet
        workbook.worksheets[2]
      end

      def columns
        @columns ||= [
          ['', 3, ->(_test) { '' }],
          ['', 3, ->(_test) { '' }],
          ['Inferno Test ID', 22, ->(test) { test.short_id.to_s }],
          ['Inferno Test Name', 65, lambda(&:title)],
          ['Inferno Test Description', 65, ->(test) { test.description&.strip }],
          ['Test Procedure Steps', 30, ->(test) { inferno_to_procedure_map[test.short_id].join(', ') }],
          ['Standard Version Filter', 30, lambda do |test|
                                            applicable_options(test).map(&:value).uniq.join(', ')
                                          end]
        ]
      end

      def add_test(test)
        this_row = columns.map do |column|
          column[2].call(test)
        end

        this_row.each_with_index do |value, index|
          inferno_worksheet.add_cell(row, index, value).change_text_wrap(true)
        end
        inferno_worksheet
          .change_row_height(row, [26, ((test.description || '').strip.lines.count * 10) + 10].max)
        inferno_worksheet.change_row_vertical_alignment(row, 'top')
        next_row
      end

      def add_group_title(group, column: 1)
        inferno_worksheet.add_cell(row, column, "#{group.short_id}: #{group.title}")
        inferno_worksheet.add_cell(row, 6, applicable_options(group).map(&:value).uniq.join(', '))
        next_row
      end

      def add_group(group)
        add_group_title(group)

        group.tests.each { |test| add_test(test) }

        group.groups.each { |nested_group| add_group(nested_group) }
      end

      def generate_inferno_test_worksheet
        workbook.add_worksheet('Inferno Tests')

        columns.each_with_index do |row_name, index|
          inferno_worksheet.add_cell(0, index, row_name.first)
        end

        self.row = 1

        test_suite.groups.each do |group|
          next if group.short_id == '6' # Skip US Core 5

          next_row
          add_group(group)
        end

        columns.each_with_index do |column, index|
          inferno_worksheet.change_column_width(index, column[1])
        end
      end
    end
  end
end
