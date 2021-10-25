require 'colorize'

module Inferno
  module Terminology
    module Tasks
      class ValidateCode
        attr_reader :system, :code, :value_set_url

        def initialize(code:, system:, valueset:)
          @code = code
          @system = system
          @value_set_url = valueset
        end

        def run
          code_display = self.system ? "#{self.system}|#{code}" : code.to_s
          if Loader.validate_code(code: code, system: self.system, valueset_url: value_set_url)
            in_system = 'is in'
            symbol = "\u2713".encode('utf-8').to_s.green
          else
            in_system = 'is not in'
            symbol = 'X'.red
          end
          system_checked = valueset || self.system

          Inferno.logger.info "#{symbol} #{code_display} #{in_system} #{system_checked}"
        end
      end
    end
  end
end
