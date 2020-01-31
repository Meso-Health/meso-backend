require 'rails_helper'

RSpec.describe EncounterRepresenter do
  let(:encounter) { build_stubbed(:encounter) }
  subject { described_class.new(encounter) }

  describe '#id' do
    it_behaves_like :allow_reads, 'id'
    it_behaves_like :allow_writes_for_new_records_only, 'id', SecureRandom.uuid
  end

  describe '#created_at' do
    it_behaves_like :allow_reads, 'created_at'
  end

  describe '#occurred_at' do
    it_behaves_like :allow_reads, 'occurred_at'
    it_behaves_like :allow_writes, 'occurred_at', 1.day.ago
  end

  describe '#backdated_occurred_at' do
    it_behaves_like :allow_reads, 'backdated_occurred_at'
    it_behaves_like :allow_writes, 'backdated_occurred_at', false, backdated_occurred_at: true
  end

  describe '#member_id' do
    it_behaves_like :allow_reads, 'member_id'
    it_behaves_like :allow_writes_for_new_records_only, 'member_id', SecureRandom.uuid
  end

  describe '#identification_event_id' do
    it_behaves_like :allow_reads, 'identification_event_id'
    it_behaves_like :allow_writes_for_new_records_only, 'identification_event_id', SecureRandom.uuid
  end

  describe '#diagnoses' do
    let(:diagnosis_ids) { create_list(:diagnosis, 2).map(&:id) }

    it_behaves_like :allow_reads, 'diagnosis_ids'

    context 'new record' do
      let(:encounter) { build(:encounter, :with_diagnoses) }

      it 'allows writing the field' do
        subject.from_hash('diagnosis_ids' => diagnosis_ids)
        expect(subject.to_hash['diagnosis_ids']).to eq diagnosis_ids
      end
    end

    context 'persisted' do
      let(:encounter) { create(:encounter, :with_diagnoses) }

      it 'allows writing the field' do
        subject.from_hash('diagnosis_ids' => diagnosis_ids)
        expect(subject.to_hash['diagnosis_ids']).to eq diagnosis_ids
      end
    end
  end

  describe '#encounter_items' do
    let(:billable) { create(:billable) }
    let(:price_schedule) { create(:price_schedule, billable: billable, provider: encounter.provider) }
    let(:new_item) {
      attributes_for(:encounter_item,
        billable_id: billable.id,
        price_schedule: price_schedule,
        encounter_id: encounter.id
      ).stringify_keys
    }

    context 'when the encounter is a new record' do
      let(:encounter) { build(:encounter) }

      it 'allows writing the field' do
        subject.from_hash('encounter_items' => [new_item])
        expect(subject.represented.encounter_items.length).to eq 1
      end
    end
  end

  describe '#forms' do
    it_behaves_like :does_not_allow_reads, 'forms'

    describe 'parsing' do
      let(:encounter) { build_stubbed(:encounter) }

      it 'adds the values as forms' do
        expect(encounter).to receive(:add_form).with('file1')
        expect(encounter).to receive(:add_form).with('file2')

        subject.from_hash('forms' => ['file1', 'file2'])
      end
    end
  end

  describe '#form_urls' do
    let(:encounter) { create(:encounter, :with_forms, forms_count: 1) }

    it 'returns the form urls' do
      expect(subject.form_urls.first).to match /^\/dragonfly\/.+$/
    end

    it 'strips EXIF info from the attachment' do
      steps = dragonfly_url_process_steps(subject.form_urls.first)
      expect(steps.map(&:args)).to include(['convert', '-strip'])
    end

    context 'when there are no forms on the encounter' do
      let(:encounter) { build_stubbed(:encounter) }

      it 'returns nil' do
        expect(subject.form_urls).to be_nil
      end
    end
  end

  describe '#clinic_number' do
    let(:encounter) { create(:encounter, identification_event: build(:identification_event, clinic_number: 123)) }

    it 'returns the clinic number associated with the identification event' do
      expect(subject.to_hash['clinic_number']).to eq(123)
    end
  end

  describe '#clinic_number_type' do
    let(:id_event) { }
    let(:encounter) { create(:encounter, identification_event: build(:identification_event, clinic_number_type: 'delivery')) }

    it 'returns the clinic number type associated with the identification event' do
      expect(subject.to_hash['clinic_number_type']).to eq 'delivery'
    end
  end

  describe '#resubmitted' do
    it_behaves_like :does_not_allow_writes_for_new_records, 'resubmitted'
    it_behaves_like :does_not_allow_writes_for_persisted_records, 'resubmitted'

    context 'has an associated resubmitted claim' do
      let(:encounter) { create(:encounter, :resubmitted) }

      it 'returns true' do
        expect(subject.to_hash['resubmitted']).to eq(true)
      end
    end

    context 'does not have an associated resubmitted claim' do
      let(:encounter) { create(:encounter) }

      it 'returns false' do
        expect(subject.to_hash['resubmitted']).to eq(false)
      end
    end
  end
end
