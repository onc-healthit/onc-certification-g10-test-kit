RSpec.describe ONCCertificationG10TestKit::ShortIDManager do
  describe '.short_id_map' do
    it 'contains a short_id for every g10 test and group' do
      runnable_ids = described_class.all_children(ONCCertificationG10TestKit::G10CertificationSuite).map(&:id)
      short_id_map = described_class.short_id_map.dup

      missing_ids = runnable_ids.reject { |id| short_id_map.delete(id).present? }

      expect(missing_ids).to be_empty, "No short_id found in short_id_map.yaml for #{missing_ids.join(', ')}."
    end

    it 'does not contain any extra short ids' do
      runnable_ids = described_class.all_children(ONCCertificationG10TestKit::G10CertificationSuite).map(&:id)
      short_id_map = described_class.short_id_map.dup

      extra_ids = short_id_map.keys - runnable_ids

      expect(extra_ids).to(
        be_empty,
        "short_id_map.yml contains the following ids which do not belong to any runnable: #{extra_ids.join(', ')}"
      )
    end
  end
end
