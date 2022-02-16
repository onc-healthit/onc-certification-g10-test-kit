require 'yaml'

module Inferno
  module Terminology
    module Tasks
      class CheckBuiltTerminology
        MIME_TYPE_SYSTEMS = [
          'http://hl7.org/fhir/ValueSet/mimetypes',
          'urn:ietf:bcp:13'
        ].freeze

        def run
          if mismatched_value_sets.blank?
            Inferno.logger.info 'Terminology built successfully.'
            return
          end

          if only_mime_types_mismatch?
            Inferno.logger.info <<~MIME
              Terminology built successfully.

              Mime-type based terminology did not match, but this can be a
              result of using a newer version of the `mime-types-data` gem and
              does not necessarily reflect a problem with the terminology build.
              The expected mime-types codes were generated with version
              `mime-types-data` version `3.2021.0901`.
            MIME
          else
            Inferno.logger.info 'Terminology build results different than expected.'
          end

          mismatched_value_sets.each do |value_set|
            Inferno.logger.info mismatched_value_set_message(value_set)
          end
        end

        def expected_manifest
          YAML.load_file(File.join(__dir__, '..', 'expected_manifest.yml'))
        end

        def new_manifest
          YAML.load_file(File.join(Dir.pwd, 'resources', 'terminology', 'validators', 'bloom', 'manifest.yml'))
        end

        def mismatched_value_sets
          @mismatched_value_sets ||=
            expected_manifest.reject do |expected_value_set|
              url = expected_value_set[:url]
              new_value_set(url) == expected_value_set
            end
        end

        def new_value_set(url)
          new_manifest.find { |value_set| value_set[:url] == url }
        end

        def only_mime_types_mismatch?
          mismatched_value_sets.all? { |value_set| MIME_TYPE_SYSTEMS.include? value_set[:url] }
        end

        def mismatched_value_set_message(expected_value_set)
          url = expected_value_set[:url]
          actual_value_set = new_value_set(url)

          "#{url}: Expected codes: #{expected_value_set[:count]} Actual codes: #{actual_value_set&.dig(:count) || 0}"
        end
      end
    end
  end
end
