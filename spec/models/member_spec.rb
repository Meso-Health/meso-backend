require 'rails_helper'

RSpec.describe Member, type: :model do
  describe 'Validations' do
    describe 'medical_record_number_from_key' do
      let(:provider1) { create(:provider) }
      let(:provider2) { create(:provider) }

      it 'returns the correct value if member has no medical record numbers stored yet' do
        member = create(:member, medical_record_numbers: {} )
        expect(member.medical_record_number_from_key(provider1.id)).to eq nil
        expect(member.medical_record_number_from_key(provider2.id)).to eq nil
        expect(member.medical_record_number_from_key(nil)).to eq nil
      end

      it 'returns the correct value if member has medical record numbers stored' do
        member = create(:member, medical_record_numbers: ({
          'primary': 12345,
          "#{provider1.id}": 67890
        }))
        expect(member.medical_record_number_from_key(provider1.id)).to eq 67890
        expect(member.medical_record_number_from_key('primary')).to eq 12345
        expect(member.medical_record_number_from_key(nil)).to eq nil
      end
    end

    describe 'card_id' do
      context 'when card_id is set' do
        it 'ensured card_id is unique' do
          card = create(:card, id: 'RWI123456')
          create(:member, card: card)

          member = Member.new(card_id: card.id)
          member.validate
          expect(member.errors[:card_id]).to_not be_empty
        end
      end

      context 'when card_id is not set' do
        it 'allows it to be nil, not an empty string' do
          member = Member.new(card_id: nil)
          member.validate
          expect(member.errors[:card_id]).to be_empty

          member = Member.new(card_id: '')
          member.validate
          expect(member.errors[:card_id]).to_not be_empty
        end
      end
    end

    describe 'preferred_language_other' do
      it 'is required when the preferred_language is other' do
        member = Member.new(preferred_language: 'rutooro')
        member.validate
        expect(member.errors[:preferred_language_other]).to be_empty

        member = Member.new(preferred_language: nil)
        member.validate
        expect(member.errors[:preferred_language_other]).to be_empty

        member = Member.new(preferred_language: 'other')
        member.validate
        expect(member.errors[:preferred_language_other]).to_not be_empty

        member = Member.new(preferred_language: 'other', preferred_language_other: 'pig latin')
        member.validate
        expect(member.errors[:preferred_language_other]).to be_empty
      end
    end
  end

  describe 'when updating the record' do
    subject { create(:member) }

    context 'when changing the card_id' do
      it 'revokes the previous card_id' do
        old_card_id = subject.card_id
        new_card_id = create(:card).id

        subject.update!(card_id: new_card_id)

        subject.reload
        expect(subject.card_id).to eq new_card_id
        expect(Card.find(old_card_id)).to be_revoked
        expect(Card.find(new_card_id)).to_not be_revoked
      end

      context 'when the save fails' do
        it 'does not revoke the previous card id if the save fails' do
          old_card_id = subject.card_id
          new_card_id = create(:member).card_id

          expect do
            subject.assign_attributes(card_id: new_card_id)
            subject.save!(validate: false)
          end.to raise_error ActiveRecord::RecordNotUnique

          subject.reload
          expect(subject.card_id).to eq old_card_id
          expect(Card.find(old_card_id)).to_not be_revoked
          expect(Card.find(new_card_id)).to_not be_revoked
        end
      end
    end

  end

  describe 'when destroying the record' do
    subject { create(:member) }

    it 'revokes the card_id' do
      subject.destroy!
      expect(Card.find(subject.card_id)).to be_revoked
    end
  end

  describe 'scopes' do
    describe '.unarchived' do
      let(:member_1) { create(:member) }
      let(:member_2) { create(:member, :archived) }
      let(:member_3) { create(:member) }

      it 'selects members that have not been archived' do
        expect(Member.unarchived).to match_array([member_1, member_3])
      end
    end

    describe '.in_administrative_division' do
      let!(:ad_1) { create(:administrative_division, :fourth) }
      let!(:ad_2) { create(:administrative_division, :fourth) }
      let(:member_1) { create(:member, household:  create(:household, administrative_division_id: ad_1.id)) }
      let(:member_2) { create(:member, household:  create(:household, administrative_division_id: ad_2.id)) }

      it 'selects members in the administrative division' do
        expect(Member.in_administrative_division(ad_1.id)).to match_array([member_1])
      end
    end

    describe '.fuzzy_matching_name' do
      let(:member_1) { create(:member, full_name: 'levenshtein') }
      let(:member_2) { create(:member, full_name: 'levnsteen') }
      let(:member_3) { create(:member, full_name: 'dumbledore') }

      it 'selects members with levenshtein distance <= 11' do
        expect(Member.fuzzy_matching_name('levenshtein')).to match_array([member_1, member_2])
      end
    end

    describe '.filter_with_params' do
      let(:card) { create(:card, id: 'ETH000012') }
      let(:membership_number) { '123456' }
      let(:member_id) { 'd80761a1-c1e7-4ed0-ba5f-b0c53b4969d4' }

      let!(:member_1) { create(:member, card: card) }
      let!(:member_2) { create(:member, membership_number: membership_number, card_id: nil) }
      let!(:member_3) { create(:member, id: member_id, card_id: nil) }
      let!(:member_4) { create(:member, medical_record_numbers: {
        "1": "1234",
        "2": "2345",
        "primary": "3456"
      })}

      it 'selects member by card_id' do
        expect(Member.filter_with_params({card_id: card.id})).to match_array([member_1])
      end

      it 'selects member by membership_number' do
        expect(Member.filter_with_params({membership_number: membership_number})).to match_array([member_2])
      end

      it 'selects member by member_id' do
        expect(Member.filter_with_params({member_id: member_id})).to match_array([member_3])
      end

      it 'selects member by medical_record_number with primary as key' do
        expect(Member.filter_with_params({medical_record_number: 1234, mrn_key: 'primary'})).to match_array([])
        expect(Member.filter_with_params({medical_record_number: 2345, mrn_key: 'primary'})).to match_array([])
        expect(Member.filter_with_params({medical_record_number: 3456, mrn_key: 'primary'})).to match_array([member_4])
      end

      it 'selects member via provider-specific medical_record_number' do
        expect(Member.filter_with_params({medical_record_number: 1234, mrn_key: 1})).to match_array([member_4])
        expect(Member.filter_with_params({medical_record_number: 1234, mrn_key: 2})).to match_array([])
        expect(Member.filter_with_params({medical_record_number: 1234, mrn_key: 3})).to match_array([])

        expect(Member.filter_with_params({medical_record_number: 2345, mrn_key: 1})).to match_array([])
        expect(Member.filter_with_params({medical_record_number: 2345, mrn_key: 2})).to match_array([member_4])
        expect(Member.filter_with_params({medical_record_number: 2345, mrn_key: 3})).to match_array([])
      end

      it 'should not select any members via primary number with non-matching key' do
        expect(Member.filter_with_params({medical_record_number: 3456, mrn_key: 1})).to match_array([])
        expect(Member.filter_with_params({medical_record_number: 3456, mrn_key: 2})).to match_array([])
        expect(Member.filter_with_params({medical_record_number: 3456, mrn_key: nil})).to match_array([])
      end

      describe 'when a member has a null membership number' do
        let(:membership_number) { nil }

        it 'does not return the null membership number for all queries' do
          expect(Member.filter_with_params({medical_record_number: 1234, mrn_key: 1})).to match_array([member_4])
        end
      end
    end

    describe '.active_at' do
      let(:enrollment_period_1) do
        create(:enrollment_period,
               start_date: Time.zone.parse('2018/10/01 EAT'),
               end_date: Time.zone.parse('2019/03/31 EAT'),
               coverage_start_date: Time.zone.parse('2019/01/01 EAT'),
               coverage_end_date: Time.zone.parse('2019/12/31 EAT'))
      end
      let(:enrollment_period_2) do
        create(:enrollment_period,
               start_date: Time.zone.parse('2019/10/01 EAT'),
               end_date: Time.zone.parse('2020/03/31 EAT'),
               coverage_start_date: Time.zone.parse('2020/01/01 EAT'),
               coverage_end_date: Time.zone.parse('2020/12/31 EAT'))
      end
      let!(:unconfirmed_member) { create(:member, :unconfirmed) }
      let!(:member_without_enrollment_records) { create(:member) }
      let(:member_with_enrollment_records) { create(:member) }
      let!(:household_enrollment_record_1) { create(:household_enrollment_record, household: member_with_enrollment_records.household, enrollment_period: enrollment_period_1, enrolled_at: Time.zone.parse('2019/01/15 EAT')) }
      let!(:household_enrollment_record_2) { create(:household_enrollment_record, household: member_with_enrollment_records.household, enrollment_period: enrollment_period_2, enrolled_at: Time.zone.parse('2019/10/15 EAT')) }
      let(:archived_member) { create(:member, archived_at: Time.zone.parse('2019/08/01 EAT'), archived_reason: 'deceased') }
      let!(:household_enrollment_record_3) { create(:household_enrollment_record, household: archived_member.household, enrollment_period: enrollment_period_1, enrolled_at: Time.zone.parse('2019/01/15 EAT')) }

      it 'returns the correct members active at a time' do
        expect(described_class.active_at(household_enrollment_record_1.enrolled_at - 1.day)).to match_array []
        expect(described_class.active_at(household_enrollment_record_1.enrolled_at)).to match_array [member_with_enrollment_records, archived_member]
        expect(described_class.active_at(household_enrollment_record_1.enrolled_at + 1.day)).to match_array [member_with_enrollment_records, archived_member]
        expect(described_class.active_at(archived_member.archived_at - 1.day)).to match_array [member_with_enrollment_records, archived_member]
        expect(described_class.active_at(archived_member.archived_at)).to match_array [member_with_enrollment_records, archived_member]
        expect(described_class.active_at(archived_member.archived_at + 1.day)).to match_array [member_with_enrollment_records]
        expect(described_class.active_at(enrollment_period_1.coverage_end_date)).to match_array [member_with_enrollment_records]
        expect(described_class.active_at(enrollment_period_1.coverage_end_date + 1.day)).to match_array [member_with_enrollment_records]
        expect(described_class.active_at(enrollment_period_2.coverage_end_date + 1.day)).to match_array []
      end
    end
  end

  describe '#absentee' do
    it 'defaults to false for a member with all information' do
      subject = build_stubbed(:member)
      expect(subject).to_not be_absentee
    end

    context 'when the member is missing photo' do
      it 'is true' do
        subject = build_stubbed(:member, photo: nil)
        expect(subject).to be_absentee
      end
    end

    context 'when the member is has no captured fingerprints' do
      subject { build_stubbed(:member, fingerprints_guid: nil) }

      context 'when the member is age 6 or older' do
        it 'is true' do
          allow(subject).to receive_messages(age: 6)
          expect(subject).to be_absentee
        end
      end

      context 'when the member is under age 6' do
        it 'is false' do
          allow(subject).to receive_messages(age: 5)
          expect(subject).to_not be_absentee
        end
      end
    end
  end

  describe "#age" do
    context 'when the birthdate accuracy is to the year' do
      it 'returns the best guess for the age' do
        member = build_stubbed(:member, birthdate: '1995/03/04')
        Timecop.freeze(2019, 1, 1) { expect(member.age).to eq 24 }
        Timecop.freeze(2020, 1, 1) { expect(member.age).to eq 25 }
        Timecop.freeze(2020, 3, 3) { expect(member.age).to eq 25 }
        Timecop.freeze(2020, 3, 5) { expect(member.age).to eq 25 }
        Timecop.freeze(2021, 1, 1) { expect(member.age).to eq 26 }
      end
    end

    context 'when the birthdate accuracy is to the month' do
      it 'returns the best guess for the age' do
        member = build_stubbed(:member, :birthdate_accurate_to_month, birthdate: '1995/03/04')
        Timecop.freeze(2020, 1,  1) { expect(member.age).to eq 24 }
        Timecop.freeze(2020, 2, 29) { expect(member.age).to eq 24 }
        Timecop.freeze(2020, 3,  3) { expect(member.age).to eq 25 }
        Timecop.freeze(2020, 3,  4) { expect(member.age).to eq 25 }
        Timecop.freeze(2020, 3,  5) { expect(member.age).to eq 25 }
        Timecop.freeze(2020, 4,  1) { expect(member.age).to eq 25 }
        Timecop.freeze(2021, 3,  1) { expect(member.age).to eq 26 }
      end
    end

    context 'when the birthdate accuracy is to the day' do
      it 'returns the best guess for the age' do
        member = build_stubbed(:member, :birthdate_accurate_to_day, birthdate: '1995/03/04')
        Timecop.freeze(2020, 1,  1) { expect(member.age).to eq 24 }
        Timecop.freeze(2020, 2, 29) { expect(member.age).to eq 24 }
        Timecop.freeze(2020, 3,  3) { expect(member.age).to eq 24 }
        Timecop.freeze(2020, 3,  4) { expect(member.age).to eq 25 }
        Timecop.freeze(2020, 3,  5) { expect(member.age).to eq 25 }
        Timecop.freeze(2020, 4,  1) { expect(member.age).to eq 25 }
        Timecop.freeze(2021, 3,  1) { expect(member.age).to eq 25 }

        member = build_stubbed(:member, :birthdate_accurate_to_day, birthdate: '1996/02/04')

      end
    end
  end

  describe '#head_of_household?' do
    subject { build(:member, relationship_to_head: relationship_to_head) }


    context 'relationship to head is self' do
      let(:relationship_to_head) { 'SELF' }

      it 'returns true' do
        expect(subject.head_of_household?).to be true
      end
    end

    context 'relationship to head is not self' do
      let(:relationship_to_head) { 'HUSBAND' }

      it 'returns false' do
        expect(subject.head_of_household?).to be false
      end
    end
  end

  describe '#archive_as_duplicate_of!' do
    context 'when other member is not nil' do
      let(:current) { create(:member) }
      let(:other) { create(:member) }

      it 'archives the current member as a duplicate' do
        current.archive_as_duplicate_of!(other)

        expect(current.archived?).to be true
        expect(current.duplicate?).to be true

        expect(other.archived?).to be false
        expect(other.duplicate?).to be false
        expect(other.has_duplicates?).to be true
      end

      it 'returns the other member' do
        expect(current.archive_as_duplicate_of!(other)).to eq other
      end
    end

    context 'when other member is nil' do
      let(:current) { create(:member) }

      it 'has no effect' do
        current.archive_as_duplicate_of!(nil)

        expect(current.archived?).to be false
        expect(current.duplicate?).to be false
      end

      it 'returns nil' do
        expect(current.archive_as_duplicate_of!(nil)).to eq nil
      end
    end
  end

  describe '#archive!' do
    let(:current) { create(:member) }

    it 'sets timestamp' do
      expect(current.archived_at).to be_nil

      current.archive! 'OTHER'

      expect(current.archived_at).to_not be_nil
    end

    it 'sets reason' do
      expect(current.archived_reason).to be_nil

      current.archive! 'OTHER'

      expect(current.archived_reason).to eq 'OTHER'
    end
  end

  specify 'archived?' do
    expect(build(:member, archived_at: Time.zone.now).archived?).to be true
    expect(build(:member, archived_at: nil).archived?).to be false
  end

  specify 'enrolled?' do
    expect(build(:member, household_id: build(:household).id).enrolled?).to be true
    expect(build(:member, household_id: nil).enrolled?).to be false
  end

  specify 'duplicate?' do
    expect(build(:member, original_member: build(:member)).duplicate?).to be true
    expect(build(:member).duplicate?).to be false
  end

  specify 'has_duplicates?' do
    original = create(:member)
    duplicate = create(:member, original_member: original)
    expect(original.has_duplicates?).to be true

    expect(build(:member).has_duplicates?).to be false
  end

  specify 'unpaid?' do
    expect(build_stubbed(:member, archived_at: nil, archived_reason: nil).unpaid?).to be false
    expect(build_stubbed(:member, archived_at: Time.zone.now, archived_reason: 'OTHER').unpaid?).to be false
    expect(build_stubbed(:member, archived_at: Time.zone.now, archived_reason: 'UNPAID').unpaid?).to be true
  end

  describe 'needs_renewal?' do
    let(:enrollment_period) { build_stubbed(:enrollment_period) }
    subject { build_stubbed(:member) }

    before { allow(subject.household).to receive(:needs_renewal?).and_return(false) }

    it 'returns nil if no enrollment period is provided' do
      expect(subject.needs_renewal?(nil)).to be nil
    end

    it 'returns true if the user is unpaid' do
      allow(subject).to receive(:unpaid?).and_return(true)
      expect(subject.needs_renewal?(enrollment_period)).to be true
    end

    it 'returns the renewal status of the household if not unpaid' do
      expect(subject.needs_renewal?(enrollment_period)).to be false
    end
  end

  describe 'active_at?' do
    let!(:enrollment_period_1) do
      create(:enrollment_period,
             start_date: Time.zone.parse('2018/10/01 EAT'),
             end_date: Time.zone.parse('2019/03/31 EAT'),
             coverage_start_date: Time.zone.parse('2019/01/01 EAT'),
             coverage_end_date: Time.zone.parse('2019/12/31 EAT'))
    end
    let!(:enrollment_period_2) do
      create(:enrollment_period,
             start_date: Time.zone.parse('2019/10/01 EAT'),
             end_date: Time.zone.parse('2020/03/31 EAT'),
             coverage_start_date: Time.zone.parse('2020/01/01 EAT'),
             coverage_end_date: Time.zone.parse('2020/12/31 EAT'))
    end

    context 'unconfirmed member' do
      let(:member) { create(:member, :unconfirmed) }

      it 'returns the correct active status' do
        expect(member.active_at?(1.day.ago)).to be false
        expect(member.active_at?(Time.zone.now)).to be false
      end
    end

    context 'member without enrollment records' do
      let(:member) { create(:member) }

      it 'returns the correct active status' do
        expect(member.active_at?(1.day.ago)).to be false
        expect(member.active_at?(Time.zone.now)).to be false
      end
    end

    context 'member with enrollment records' do
      let(:member) { create(:member) }
      let!(:household_enrollment_record_1) { create(:household_enrollment_record, household: member.household, enrollment_period: enrollment_period_1, enrolled_at: Time.zone.parse('2019/01/15 EAT')) }
      let!(:household_enrollment_record_2) { create(:household_enrollment_record, household: member.household, enrollment_period: enrollment_period_2, enrolled_at: Time.zone.parse('2019/10/15 EAT')) }

      it 'returns the correct active status' do
        expect(member.active_at?(household_enrollment_record_1.enrolled_at - 1.day)).to be false
        expect(member.active_at?(household_enrollment_record_1.enrolled_at)).to be true
        expect(member.active_at?(household_enrollment_record_1.enrolled_at + 1.day)).to be true
        expect(member.active_at?(enrollment_period_1.coverage_end_date)).to be true
        expect(member.active_at?(enrollment_period_1.coverage_end_date + 1.day)).to be true
        expect(member.active_at?(enrollment_period_2.coverage_end_date + 1.day)).to be false
      end
    end

    context 'archived member' do
      let(:member) { create(:member, archived_at: Time.zone.parse('2019/08/01 EAT'), archived_reason: 'deceased') }
      let!(:household_enrollment_record) { create(:household_enrollment_record, household: member.household, enrollment_period: enrollment_period_1, enrolled_at: Time.zone.parse('2019/01/15 EAT')) }

      it 'returns the correct active status' do
        expect(member.active_at?(member.archived_at - 1.day)).to be true
        expect(member.active_at?(member.archived_at)).to be true
        expect(member.active_at?(member.archived_at + 1.day)).to be false
      end
    end
  end

  describe 'coverage_end_date' do
    let(:enrollment_period_1) {
      create(
        :enrollment_period,
        start_date: 2.years.ago,
        end_date: 1.year.ago,
        coverage_start_date: 2.years.ago,
        coverage_end_date: 1.year.ago,
      )
    }
    let(:enrollment_period_2) {
      create(
        :enrollment_period,
        start_date: Time.zone.now,
        end_date: 1.year.from_now,
        coverage_start_date: Time.zone.now,
        coverage_end_date: 1.year.from_now,
      )
    }
    let(:household_enrollment_record_1) { create(:household_enrollment_record, enrollment_period: enrollment_period_1) }
    let(:household_enrollment_record_2) { create(:household_enrollment_record, enrollment_period: enrollment_period_2) }
    let(:household) { create(:household, household_enrollment_records: [household_enrollment_record_2, household_enrollment_record_1]) }
    subject { create(:member, household: household) }

    it 'returns the coverage end date from the most recent enrollment' do
      expect(subject.coverage_end_date).to eq enrollment_period_2.coverage_end_date
    end
  end

  describe 'renewed_at' do
    let(:household_enrollment_record_1) { create(:household_enrollment_record, enrolled_at: 1.year.ago) }
    let(:household_enrollment_record_2) { create(:household_enrollment_record, enrolled_at: 1.year.from_now) }
    let(:household) { create(:household, household_enrollment_records: [household_enrollment_record_2, household_enrollment_record_1]) }
    subject { create(:member, household: household) }

    it 'returns the enrolled_at date of the most recent enrollment' do
      # add reload to avoid test failing when run on CI due to lack of DB time precision
      expect(subject.renewed_at).to eq household_enrollment_record_2.reload.enrolled_at
    end
  end
end
