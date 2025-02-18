module ONCCertificationG10TestKit
  module Feature
    class << self # rubocop:disable Lint/EmptyClass
      # This is how you can define feature flags to be used in the g10 test kit
      # def us_core_v4?
      #   ENV.fetch('US_CORE_4_ENABLED', 'false')&.casecmp?('true')
      # end
    end
  end
end
