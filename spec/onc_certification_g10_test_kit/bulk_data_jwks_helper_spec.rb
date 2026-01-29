require_relative '../../lib/onc_certification_g10_test_kit/bulk_data_jwks_helper'
require 'json'

RSpec.describe ONCCertificationG10TestKit::BulkDataJWKSHelper do
  describe '.jwks_json' do
    let(:jwks_json) { described_class.jwks_json }
    let(:jwks) { JSON.parse(jwks_json) }

    it 'returns a valid JSON' do
      expect { JSON.parse(jwks_json) }.to_not raise_error
    end

    it 'contains all keys (including sign keys)' do
      expect(jwks['keys'].any? { |key| key['key_ops'].include?('sign') }).to be(true)
    end
  end

  describe '.public_jwks_json' do
    let(:jwks_json) { described_class.public_jwks_json }
    let(:jwks) { JSON.parse(jwks_json) }

    it 'returns a valid JSON' do
      expect { JSON.parse(jwks_json) }.to_not raise_error
    end

    it 'contains only keys with "verify" operation' do
      jwks['keys'].each do |key|
        expect(key['key_ops']).to include('verify')
        expect(key['key_ops']).to_not include('sign')
      end
    end

    it 'contains at least one key' do
      expect(jwks['keys']).to_not be_empty
    end
  end
end
