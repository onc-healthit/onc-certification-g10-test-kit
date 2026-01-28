require 'json'

module ONCCertificationG10TestKit
  module BulkDataJWKSHelper
    def self.jwks_json
      @jwks_json ||= File.read(ENV.fetch('G10_BULK_DATA_JWKS', File.join(__dir__, 'bulk_data_jwks.json')))
    end
  end
end
