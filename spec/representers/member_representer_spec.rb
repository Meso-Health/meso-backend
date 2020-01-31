require 'rails_helper'

RSpec.describe MemberRepresenter do
  let(:member) { build_stubbed(:member) }
  let(:mrn_key) { nil }
  subject { described_class.new(member) }

  describe '#id' do
    it_behaves_like :allow_reads, 'id'
    it_behaves_like :allow_writes_for_new_records_only, 'id', SecureRandom.uuid
  end

  describe '#household_id' do
    it_behaves_like :allow_reads, 'household_id'
    it_behaves_like :allow_writes_for_new_records_only, 'household_id', SecureRandom.uuid
  end

  describe '#enrolled_at' do
    it_behaves_like :allow_reads, 'enrolled_at'
    it_behaves_like :allow_writes_for_new_records_only, 'enrolled_at', 1.day.ago
  end

  describe '#administrative_division_id' do
    context 'parsing' do
      let(:member) { build_stubbed(:member) }

      context 'when the member is currently assigned to a household' do
        it 'returns the administrative division id of the household' do
          administrative_division = build_stubbed(:administrative_division)
          household = build_stubbed(:household, administrative_division_id: administrative_division.id)
          allow(member).to receive_messages(household: household)
          expect(subject.to_hash['administrative_division_id']).to eq household.administrative_division_id
        end
      end

      context 'when the member is not currently assigned to a household' do
        it 'returns nil' do
          allow(member).to receive_messages(household: nil)
          expect(subject.to_hash['administrative_division_id']).to be_nil
        end
      end
    end
  end

  describe '#photo_url' do
    let(:member) { create(:member) }

    it 'returns the photo url' do
      expect(subject.photo_url).to match /^\/dragonfly\/.+$/
    end

    it 'strips EXIF info from the attachment' do
      steps = dragonfly_url_process_steps(subject.photo_url)
      expect(steps.map(&:args)).to include(['convert', '-strip'])
    end

    context 'when there is no photo' do
      let(:member) { create(:member, photo: nil) }

      it 'returns nil' do
        expect(subject.photo_url).to be_nil
      end
    end
  end

  describe '#national_id_photo_url' do
    let(:member) { create(:member, :with_national_id_photo) }

    it 'returns the national_id_photo url' do
      expect(subject.national_id_photo_url).to match /^\/dragonfly\/.+$/
    end

    it 'strips EXIF info from the attachment' do
      steps = dragonfly_url_process_steps(subject.national_id_photo_url)
      expect(steps.map(&:args)).to include(['convert', '-strip'])
    end

    context 'when there is no national_id_photo' do
      let(:member) { create(:member) }

      it 'returns nil' do
        expect(subject.national_id_photo_url).to be_nil
      end
    end
  end

  describe '#medical_record_number' do
    let(:medical_record_numbers) do
      {
        '1' => '16414',
        '2' => '27128',
      }
    end
    let(:member) { create(:member, medical_record_numbers: medical_record_numbers) }

    it 'medical_record_number returns the MRN based on the supplied mrn_key' do
      expect(subject.to_hash(mrn_key: '1')['medical_record_number']).to eq '16414'
      expect(subject.to_hash(mrn_key: '2')['medical_record_number']).to eq '27128'
      expect(subject.to_hash(mrn_key: nil)['medical_record_number']).to eq nil
    end

    it 'medical_record_numbers returns the entire MRN hash' do
      expect(subject.to_hash['medical_record_numbers']).to eq medical_record_numbers
    end
  end
end
