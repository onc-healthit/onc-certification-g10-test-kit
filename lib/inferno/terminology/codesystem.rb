require_relative '../exceptions'
require_relative 'bcp_13'
require_relative 'bcp47'

module Inferno
  module Terminology
    class Codesystem
      attr_accessor :codesystem_model

      def initialize(cs_model)
        @codesystem_model = cs_model
      end

      def all_codes_in_concept(concepts)
        Set.new.tap { |cs_set| load_codes(concepts.flatten, cs_set) }
      end

      def load_codes(concepts, cs_set)
        concepts.each do |concept|
          cs_set.add(system: codesystem_model.url, code: concept.code)
          load_codes(concept.concept, cs_set) unless concept.concept.blank?
        end
      end

      def find_concept(code, concepts = codesystem_model.concept)
        return if concepts.nil?

        concepts.find do |concept|
          concept.code == code || find_concept(code, concept.concept)
        end
      end

      def is_a_concept_filter?(filter) # rubocop:disable Naming/PredicateName
        (filter.op == 'is-a') && (codesystem_model.hierarchyMeaning == 'is-a') && (filter.property == 'concept')
      end

      def filter_codes(filter = nil)
        if filter.nil?
          all_codes_in_concept(codesystem_model.concept)
        elsif is_a_concept_filter? filter
          parent_concept = find_concept(filter.value)
          all_codes_in_concept([parent_concept])
        else
          raise FilterOperationException, filter.to_s
        end
      end
    end
  end
end
