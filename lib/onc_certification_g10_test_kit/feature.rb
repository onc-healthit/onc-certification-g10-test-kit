module ONCCertificationG10TestKit
  module Feature
    class << self
      def use_new_resource_validator?
        ENV.fetch('USE_NEW_RESOURCE_VALIDATOR', 'false')&.casecmp?('true')
      end
    end
  end
end
