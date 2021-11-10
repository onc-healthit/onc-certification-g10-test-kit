module Inferno
  module Terminology
    module BCP13
      @code_set = nil

      def self.code_set
        @code_set ||= parse_code_set
      end

      def self.parse_code_set
        require 'mime/types'
        cs_set = Set.new
        MIME::Types.each do |type|
          cs_set.add(system: 'urn:ietf:bcp:13', code: preprocess_code(type.simplified))
        end
        cs_set
      end

      # "preprocess" step for BCP13 codes, to remove any of the optional parameters
      # and downcase them
      def self.preprocess_code(code)
        code&.split(';')&.first&.downcase
      end
    end
  end
end
