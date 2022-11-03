require_relative 'terminology_configuration'

module Inferno
  module Terminology
    class Validator
      attr_reader :url, :concept_count, :type, :code_systems, :file_name, :bloom_filter

      def initialize(metadata)
        @url = metadata[:url]
        @concept_count = metadata[:count]
        @type = metadata[:type]
        @code_systems = metadata[:code_systems]
        @file_name = metadata[:file]
        @bloom_filter = metadata[:bloom_filter]
      end

      def validate(code:, system: nil)
        if system
          raise ProhibitedSystemException, system if TerminologyConfiguration.system_prohibited?(system)

          coding_in_filter?(code:, system:)
        elsif contains_prohibited_systems?
          raise ProhibitedSystemException, prohibited_systems.join(', ') unless code_in_allowed_system?(code)

          true
        else
          code_in_any_system?(code)
        end
      end

      def contains_prohibited_systems?
        prohibited_systems.present?
      end

      def prohibited_systems
        @prohibited_systems ||=
          code_systems.select { |system| TerminologyConfiguration.system_prohibited?(system) }
      end

      def allowed_systems
        @allowed_systems ||=
          code_systems.select { |system| TerminologyConfiguration.system_allowed?(system) }
      end

      def code_in_allowed_system?(code)
        code_in_systems?(code, allowed_systems)
      end

      def code_in_any_system?(code)
        code_in_systems?(code, code_systems)
      end

      def code_in_systems?(code, possible_systems)
        possible_systems.any? do |possible_system|
          coding_in_filter?(code:, system: possible_system)
        end
      end

      def coding_in_filter?(code:, system:)
        bloom_filter.include? "#{system}|#{code}"
      end
    end
  end
end
