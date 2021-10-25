module Inferno
  module Terminology
    class Validator
      attr_reader :url, :concept_count, :type, :code_systems, :file_name, :bloom_filter

      def initialize(**params)
        @url = params[:url]
        @concept_count = params[:count]
        @type = params[:type]
        @code_systems = params[:code_systems]
        @file_name = params[:file]
        @bloom_filter = params[:bloom_filter]
      end

      def validate(code:, system: nil)
        if system
          coding_in_filter?(code: code, system: system)
        else
          code_systems.any? do |possible_system|
            coding_in_filter?(code: code, system: possible_system)
          end
        end
      end

      private

      def coding_in_filters?(code:, system:)
        bloom_filter.include? "#{system}|#{code}"
      end
    end
  end
end

