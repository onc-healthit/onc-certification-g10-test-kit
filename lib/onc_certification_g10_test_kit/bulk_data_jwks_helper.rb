require 'json'

module ONCCertificationG10TestKit
  module BulkDataJWKSHelper
    def self.jwks_json
      @jwks_json ||= File.read(ENV.fetch('G10_BULK_DATA_JWKS', File.join(__dir__, 'bulk_data_jwks.json')))
    end

    def self.public_jwks_json
      @public_jwks_json ||=
        begin
          jwks = JSON.parse(jwks_json)
          JSON.pretty_generate(
            { keys: jwks['keys'].select { |key| key['key_ops']&.include?('verify') } }
          )
        end
    end
  end
end
