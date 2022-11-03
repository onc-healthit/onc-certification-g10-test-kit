require 'colorize'
require_relative '../terminology_validation'
require_relative '../loader'

module Inferno
  module Terminology
    module Tasks
      class ValidateCode
        include TerminologyValidation

        attr_reader :system, :code, :value_set_url

        def initialize(code:, system:, valueset:)
          @code = code
          @system = system
          @value_set_url = valueset
        end

        def run
          Inferno::Terminology::Loader.load_validators
          code_display = self.system ? "#{self.system}|#{code}" : code.to_s
          if validate_code(code:, system: self.system, value_set_url:)
            in_system = 'is in'
            symbol = "\u2713".encode('utf-8').to_s.green
          else
            in_system = 'is not in'
            symbol = 'X'.red
          end
          system_checked = value_set_url || self.system

          Inferno.logger.info "#{symbol} #{code_display} #{in_system} #{system_checked}"
        end
      end
    end
  end
end
