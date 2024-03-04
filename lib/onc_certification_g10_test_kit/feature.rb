module ONCCertificationG10TestKit
  module Feature
    class << self
      def use_hl7_resource_validator?
        ENV.fetch('USE_HL7_RESOURCE_VALIDATOR', 'false')&.casecmp?('true')
      end
    end
  end
end
