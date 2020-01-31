require 'rails_helper'

RSpec.describe IdentificationEventRepresenter do
  let(:encounter) { build_stubbed(:encounter) }
  subject { described_class.new(encounter) }

  describe '#id' do
    it_behaves_like :allow_reads, 'id'
    it_behaves_like :allow_writes_for_new_records_only, 'id', SecureRandom.uuid
  end

  describe '#occurred_at' do
    it_behaves_like :allow_reads, 'occurred_at'
    it_behaves_like :allow_writes_for_new_records_only, 'occurred_at', 1.day.ago
  end

  describe '#member_id' do
    it_behaves_like :allow_reads, 'member_id'
    it_behaves_like :allow_writes_for_new_records_only, 'member_id', SecureRandom.uuid
  end

  describe '#accepted' do
    it_behaves_like :allow_reads, 'accepted'
    it_behaves_like :allow_writes_for_new_records_only, 'accepted', false, accepted: true
  end

  describe '#search_method' do
    it_behaves_like :allow_reads, 'search_method'
    it_behaves_like :allow_writes_for_new_records_only, 'search_method', 'search_name', search_method: 'scan_barcode'
  end

  describe '#photo_verified' do
    it_behaves_like :allow_reads, 'photo_verified'
    it_behaves_like :allow_writes_for_new_records_only, 'photo_verified', false, photo_verified: true
  end

  describe '#through_member_id' do
    it_behaves_like :allow_reads, 'through_member_id'
    it_behaves_like :allow_writes_for_new_records_only, 'through_member_id', SecureRandom.uuid
  end

  describe '#clinic_number' do
    it_behaves_like :allow_reads, 'clinic_number'
    it_behaves_like :allow_writes_for_new_records_only, 'clinic_number', 234, clinic_number: 123
  end

  describe '#clinic_number_type' do
    it_behaves_like :allow_reads, 'clinic_number_type'
    it_behaves_like :allow_writes_for_new_records_only, 'clinic_number_type', 'delivery', clinic_number_type: 'opd'
  end
end
