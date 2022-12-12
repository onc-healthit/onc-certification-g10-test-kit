require_relative '../repositiories/validators'
require_relative '../terminology/bcp_13'

module Inferno
  module Terminology
    module TerminologyValidation
      # CodeSystems/ValueSets to "preprocess" prior to validation, and the
      # function to use
      PREPROCESS_FUNCS = {
        'urn:ietf:bcp:13' => BCP13.method(:preprocess_code),
        'http://hl7.org/fhir/ValueSet/mimetypes' => BCP13.method(:preprocess_code)
      }.freeze

      def validators_repo
        @validators_repo ||= Repositories::Validators.new
      end

      # This function accepts a valueset URL, code, and optional system, and
      # returns true if the code or code/system combination is valid for the
      # valueset represented by that URL
      #
      # @param String value_set_url the URL for the valueset to validate against
      # @param String code the code to validate against the valueset
      # @param String system an optional codesystem to validate against.
      # @return Boolean whether the code or code/system is in the valueset
      def validate_code(code:, value_set_url: nil, system: nil)
        # Before we validate the code, see if there's any preprocessing steps we have to do
        # To get the code "ready" for validation
        code = PREPROCESS_FUNCS[system].call(code) if PREPROCESS_FUNCS[system]
        code = PREPROCESS_FUNCS[value_set_url].call(code) if PREPROCESS_FUNCS[value_set_url]

        # Get the valueset from the url. Redundant if the 'system' is not nil,
        # but allows us to throw a better error if the valueset isn't known by Inferno
        validator =
          if value_set_url
            validators_repo.find(value_set_url) || raise(UnknownValueSetException, value_set_url)
          else
            validators_repo.find(system) || raise(UnknownCodeSystemException, system)
          end

        validator.validate(code:, system:)
      end
    end
  end
end
