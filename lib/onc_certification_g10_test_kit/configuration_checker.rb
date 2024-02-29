require_relative '../inferno/terminology/tasks/check_built_terminology'

module ONCCertificationG10TestKit
  class ConfigurationChecker
    EXPECTED_VALIDATOR_VERSION = '2.3.2'.freeze
    EXPECTED_HL7_VALIDATOR_VERSION = '"6.2.16-SNAPSHOT"'.freeze

    def configuration_messages
      validator_version_message + terminology_messages + version_message
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
      if Feature.use_hl7_resource_validator?
        expected_validator_version = EXPECTED_HL7_VALIDATOR_VERSION
        validator_version_url = "#{validator_url}/validator/version"
      else
        expected_validator_version = EXPECTED_VALIDATOR_VERSION
        validator_version_url = "#{validator_url}/version"
      end

      response = Faraday.get validator_version_url
      if response.body.starts_with? '{'
        version_json = JSON.parse(response.body)
        version = version_json['inferno-framework/fhir-validator-wrapper']
      else
        version = response.body
      end

      if version == expected_validator_version
        [{
          type: 'info',
          message: "FHIR validator is the expected version `#{expected_validator_version}`"
        }]
      else
        [{
          type: 'error',
          message: "Expected FHIR validator version `#{expected_validator_version}`, but found `#{version}`"
        }]
      end
    rescue JSON::ParserError => e
      [{
        type: 'error',
        message: "Unable to parse Validator version '`#{response.body}`'. Parser error: `#{e.message}`"
      }]
    rescue StandardError => e
      [{
        type: 'error',
        message: "Unable to connect to Validator: `#{e.message}`"
      }]
    end

    def code_system_version_messages
      path = File.join('resources', 'terminology', 'validators', 'bloom', 'metadata.yml')
      return '' unless File.exist? path

      cs_metadata = YAML.load_file(path)
      message = "Terminology was generated based on the following code system versions:\n"
      cs_metadata.each do |_url, metadata|
        message += "* #{metadata[:name]}: version #{metadata[:versions].join(', ')}\n"
      end

      message
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
        elsif terminology_checker.class::NON_UMLS_SYSTEMS.include? url
          warning_messages <<
            "* `#{url}`: Expected codes: #{expected_value_set[:count]} Actual codes: #{actual_value_set[:count]}"
        else
          error_messages <<
            "* `#{url}`: Expected codes: #{expected_value_set[:count]} Actual codes: #{actual_value_set[:count]}"
        end
      end

      code_system_messages = code_system_version_messages

      if code_system_version_messages.present?
        messages << {
          type: 'info',
          message: code_system_messages
        }
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
          Some terminology not based on UMLS did not match, but this can be a
          result of these terminologies having a different update schedule than
          UMLS. As long as the actual number of codes is close to the expected
          number, this does not does not reflect a problem with the terminology
          build.
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

    def version_message
      return [] if VERSION.match?(/\A\d+\.\d+\.\d+\z/)

      [{
        type: 'error',
        message: <<~MESSAGE
          This is a development version (`#{VERSION}`) of the ONC Certification
          (g)(10) Standardized API Test Kit and is not suitable for
          certification. Please [download an official
          release](https://github.com/onc-healthit/onc-certification-g10-test-kit/releases)
          if you did not intend to use the development version.
        MESSAGE
      }]
    end
  end
end
