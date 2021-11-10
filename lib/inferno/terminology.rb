require_relative 'terminology/loader'

module Inferno
  module Terminology
    PACKAGE_DIR = File.join('tmp', 'terminology', 'fhir')

    def self.code_system_metadata
      @code_system_metadata ||=
        if File.file? File.join('resources', 'terminology', 'validators', 'bloom', 'metadata.yml')
          YAML.load_file(File.join('resources', 'terminology', 'validators', 'bloom', 'metadata.yml'))
        else
          {}
        end
    end
  end
end
