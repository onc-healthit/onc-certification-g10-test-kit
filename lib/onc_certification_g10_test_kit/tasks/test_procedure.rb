# frozen_string_literal: true

module ONCCertificationG10TestKit
  module Tasks
    class TestProcedure
      # procedure -> section -> steps
      attr_accessor :sections

      def initialize(data)
        @sections = data[:procedure].map { |section| Section.new(section) }
      end

      class Section
        attr_accessor :name, :steps

        def initialize(data)
          @name = data[:section]

          group = nil
          @steps = data[:steps].map do |step|
            if step[:group].nil?
              step[:group] = group
            else
              group = step[:group]
            end

            Step.new(step)
          end
        end
      end

      class Step
        attr_accessor :group, :id, :s_u_t, :t_l_v, :inferno_supported, :inferno_notes, :inferno_tests, :alternate_test

        def initialize(data)
          @group = data[:group]
          @id = data[:id]
          @s_u_t = data[:SUT]
          @t_l_v = data[:TLV]
          @inferno_supported = data[:inferno_supported]
          @inferno_notes = data[:inferno_notes]
          @alternate_test = data[:alternate_test]
          @inferno_tests = expand_tests(data[:inferno_tests]).flatten
        end

        def expand_tests(test_list)
          return [] if test_list.nil?

          test_list.map do |test|
            if test.include?(' - ')
              first, second = test.split(' - ')
              prefix, _, beginning = first.rpartition('.')
              second_prefix, _, ending = second.rpartition('.')
              raise "'#{prefix}' != '#{second_prefix}' in #{@group} #{@id}" unless prefix == second_prefix

              (beginning.to_i..ending.to_i).map { |index| "#{prefix}.#{format('%02<index>d', { index: })}" }
            else
              [test]
            end
          end
        end
      end
    end
  end
end
