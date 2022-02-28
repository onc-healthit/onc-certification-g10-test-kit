require_relative '../inferno/terminology/tasks/check_built_terminology'

module ONCCertificationG10TestKit
  class ConfigurationChecker
    EXPECTED_VALIDATOR_VERSION = '2.1.0'.freeze

    def configuration_messages
      validator_version_message + terminology_messages
    end

    def terminology_checker
      @terminology_checker ||= Inferno::Terminology::Tasks::CheckBuiltTerminology.new
    end

    def mismatched_value_sets
      terminology_checker.mismatched_value_sets
    end

    def validator_url
      @validator_url ||= G10CertificationSuite.find_validator(:default).url
    end

    def validator_version_message
      response = Faraday.get "#{validator_url}/version"
      version = response.body

      if version == EXPECTED_VALIDATOR_VERSION
        [{
          type: 'info',
          message: "FHIR validator is the expected version `#{EXPECTED_VALIDATOR_VERSION}`"
        }]
      else
        [{
          type: 'error',
          message: "Expected FHIR validator version `#{EXPECTED_VALIDATOR_VERSION}`, but found `#{version}`"
        }]
      end
    rescue StandardError => e
      [{
        type: 'error',
        message: "Unable to connect to Validator: `#{e.message}`"
      }]
    end

    def terminology_messages # rubocop:disable Metrics/CyclomaticComplexity
      success_messages = []
      warning_messages = []
      error_messages = []
      messages = []
      terminology_checker.expected_manifest.each do |expected_value_set|
        url = expected_value_set[:url]
        actual_value_set = terminology_checker.new_value_set(url)

        if actual_value_set == expected_value_set
          success_messages << "* `#{url}`: #{actual_value_set[:count]} codes"
        elsif actual_value_set.nil?
          error_messages << "* `#{url}`: Not loaded"
        elsif terminology_checker.class::MIME_TYPE_SYSTEMS.include? url
          warning_messages <<
            "* `#{url}`: Expected codes: #{expected_value_set[:count]} Actual codes: #{actual_value_set[:count]}"
        else
          error_messages <<
            "* `#{url}`: Expected codes: #{expected_value_set[:count]} Actual codes: #{actual_value_set[:count]}"
        end
      end

      if success_messages.present?
        messages << {
          type: 'info',
          message:
            "The following value sets and code systems have been properly loaded:\n#{success_messages.join("\n")}"
        }
      end

      if warning_messages.present?
        warning_message = <<~WARNING
          Mime-type based terminology did not exactly match. This can be the
          result of using a slightly different version of the `mime-types-data`
          gem and does not reflect a problem with the terminology build as long
          as the expected and actual number of codes are close to each other.
        WARNING
        messages << {
          type: 'warning',
          message: warning_message + warning_messages.join("\n")
        }
      end

      if error_messages.present?
        error_message = <<~ERROR
          There is a problem with the terminology resources. See the README for
          the [G10 Certification Test Kit
          README](https://github.com/inferno-framework/g10-certification-test-kit#terminology-support)
          for instructions on building the required terminology resources:\n
        ERROR
        messages << {
          type: 'error',
          message: error_message + error_messages.join("\n")
        }
      end

      messages
    end
  end
end
