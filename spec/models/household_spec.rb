require 'rails_helper'

RSpec.describe Household, type: :model do
  describe '#head_of_household' do
    context 'when there is no one in the household' do
      let!(:household) { create(:household) }

      it 'should return nil' do
        expect(household.head_of_household).to be nil
      end
    end

    context 'when there is one head of household' do
      let!(:household) { create(:household) }
      let!(:member) { create(:member, relationship_to_head: 'SELF', household: household) }
      let!(:member2) { create(:member, relationship_to_head: 'BABY', household: household) }


      it 'should return that member' do
        expect(household.head_of_household).to eq member
      end
    end

    context 'when there is no head of household' do
      let!(:household) { create(:household) }
      let!(:member) { create(:member, relationship_to_head: nil, household: household) }
      let!(:member2) { create(:member, relationship_to_head: nil, household: household) }

      it 'should return nil' do
        expect(household.head_of_household).to be nil
      end
    end

    context 'when there is more than one head of household' do
      let!(:household) { create(:household) }
      let!(:member) { create(:member, relationship_to_head: 'SELF', household: household) }
      let!(:member2) { create(:member, relationship_to_head: 'SELF', household: household) }

      it 'should return the first member' do
        expect(household.head_of_household).to eq member
      end
    end
  end

  describe '#merge!' do
    it 'overwrites no attributes in the current household from the other household' do
      current = create(:household, enrolled_at: 1.days.ago)
      other = create(:household, enrolled_at: 2.days.ago)

      current_attrs_was = current.attributes.dup
      other_attrs_was = other.attributes.dup

      current.merge!(other)

      not_changed = Household.column_names - %w[created_at updated_at enrolled_at merged_from_household_id]
      expect(current.attributes.slice(*not_changed)).to eq current_attrs_was.slice(*not_changed)
      expect(current.created_at).to match_timestamp current_attrs_was['created_at']
      expect(current.enrolled_at).to match_timestamp current_attrs_was['enrolled_at']
    end

    it 'moves all members from the other household into the current household' do
      current = create(:household, :with_members)
      other = create(:household, :with_members)

      current_member_ids = current.members.pluck(:id)
      other_member_ids = other.members.pluck(:id)

      current.merge!(other)

      expect(current.members.count).to eq 4
      expect(current.members.pluck(:id)).to match_array(current_member_ids + other_member_ids)
    end

    it 'assigns the other household ID to the current household #merged_from_household_id' do
      current = create(:household)
      other = create(:household)
      current.merge!(other)

      expect(current.merged_from_household_id).to eq other.id
    end

    it 'destroys the other household' do
      other = create(:household)
      create(:household).merge!(other)

      expect(other).to be_destroyed
    end

    it 'returns the current household' do
      current = create(:household)
      expect(current.merge!(create(:household))).to be current
    end

    context 'when passed attributes to overwrite' do
      it 'overwrites the existing values on the current household with those on the other household' do
        current = create(:household)
        other = create(:household)

        other_attrs_was = other.attributes.dup

        attributes_to_overwrite = %w[latitude longitude]
        current.merge!(other, attributes_to_overwrite)

        expect(current.attributes.slice(*attributes_to_overwrite)).to eq other_attrs_was.slice(*attributes_to_overwrite)
      end
    end
  end

  describe '#needs_renewal?' do
    let!(:older_enrollment_period) { create(:enrollment_period) }
    let!(:most_recent_enrollment_period) { create(:enrollment_period, :in_progress) }
    let!(:household) { create(:household) }

    subject { household.needs_renewal?(most_recent_enrollment_period_id) }

    context 'most_recent_enrollment_period_id is nil' do
      let(:most_recent_enrollment_period_id) { nil }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'most_recent_enrollment_period_id is not nil' do
      let(:most_recent_enrollment_period_id) { most_recent_enrollment_period.id }

      context 'household has no household enrollment records' do
        it 'returns true' do
          expect(subject).to be true
        end
      end

      context 'household has household enrollment record for older enrollment period' do
        before do
          create(:household_enrollment_record, household: household, enrollment_period: older_enrollment_period)
        end

        it 'returns true' do
          expect(subject).to be true
        end
      end

      context 'household has household enrollment record for most recent enrollment period' do
        before do
          create(:household_enrollment_record, household: household, enrollment_period: older_enrollment_period)
          create(:household_enrollment_record, household: household, enrollment_period: most_recent_enrollment_period)
        end

        it 'returns false' do
          expect(subject).to be false
        end
      end
    end
  end
end
