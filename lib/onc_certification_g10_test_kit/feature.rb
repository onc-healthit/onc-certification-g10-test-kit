module ONCCertificationG10TestKit
  module Feature
    class << self
      def us_core_v4?
        ENV.fetch('US_CORE_4_ENABLED', 'false')&.casecmp?('true')
      end

      def bulk_data_v2?
        ENV.fetch('BULk_DATA_V2_ENABLED', 'false')&.casecmp?('true')
      end 
    end
  end
end
