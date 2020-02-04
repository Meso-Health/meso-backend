require 'rails_helper'

RSpec.describe EnrollmentPeriod, type: :model do
  describe 'Validation' do
    describe 'valid_dates' do
      let!(:administrative_division) { create(:administrative_division) }
      let!(:another_administrative_division) { create(:administrative_division) }
      let!(:enrollment_period) { create(:enrollment_period, start_date: 10.days.ago, end_date: 4.days.ago, administrative_division: administrative_division) }

      it 'does not allow administrative_division to be nil' do
        enrollment_period.administrative_division = nil
        expect(enrollment_period).to_not be_valid
      end

      it 'does not allow start_date to overlap with a previous enrollment periods' do
        expect(build(:enrollment_period, start_date: 5.days.ago, end_date: 5.days.from_now, administrative_division: administrative_division)).to_not be_valid

        # End date overlaps
        expect(build(:enrollment_period, start_date: 15.days.ago, end_date: 9.days.ago, administrative_division: administrative_division)).to_not be_valid

        # Another enrollment period is a subset of this newly created enrollment period
        expect(build(:enrollment_period, start_date: 15.days.ago, end_date: 5.days.from_now, administrative_division: administrative_division)).to_not be_valid
        
        # Same start date.
        expect(build(:enrollment_period, start_date: enrollment_period.start_date, end_date: 5.days.from_now, administrative_division: administrative_division)).to_not be_valid
      end

      it 'does not allow coverage_start_date to equal or after coverage_end_date' do
        ten_days_ago = 10.days.ago
        expect(build(:enrollment_period, start_date: 3.days.ago, end_date: 9.days.ago, coverage_start_date: ten_days_ago, coverage_end_date: ten_days_ago)).to_not be_valid
        expect(build(:enrollment_period, start_date: 3.days.ago, end_date: 9.days.ago, coverage_start_date: 10.days.ago, coverage_end_date: 9.days.ago)).to_not be_valid
      end

      it 'does not allow start_date to be after the coverage_start_date' do
        expect(build(:enrollment_period, start_date: 3.days.ago, end_date: 9.days.ago, coverage_start_date: 4.days.ago)).to_not be_valid
      end

      it 'allow non-overlapping enrollment periods to be created.' do
        expect(build(:enrollment_period, start_date: 2.days.ago, end_date: 5.days.from_now, administrative_division: administrative_division)).to be_valid
        expect(build(:enrollment_period, start_date: 10.days.from_now, end_date: 365.days.from_now, administrative_division: administrative_division)).to be_valid
      end

      it 'does not allow nil start_date' do
        enrollment_period2 = build(:enrollment_period, start_date: nil, end_date: 5.days.ago, administrative_division: administrative_division)
        expect(enrollment_period2).to_not be_valid
      end

      it 'does not allow nil end_date' do
        enrollment_period2 = build(:enrollment_period, start_date: 3.days.ago, end_date: nil, administrative_division: administrative_division)
        expect(enrollment_period2).to_not be_valid
      end

      it 'does not allow nil coverage_start_date' do
        enrollment_period2 = build(:enrollment_period, start_date: 3.days.ago, end_date: 5.days.from_now, coverage_start_date: nil, administrative_division: administrative_division)
        expect(enrollment_period2).to_not be_valid
      end

      it 'does not allow nil coverage_end_date' do
        enrollment_period2 = build(:enrollment_period, start_date: 3.days.ago, end_date: 5.days.from_now, coverage_end_date: nil, administrative_division: administrative_division)
        expect(enrollment_period2).to_not be_valid
      end

      it 'does not allow start_date to be after end_date' do
        enrollment_period2 = build(:enrollment_period, start_date: 3.days.ago, end_date: 5.days.ago, administrative_division: administrative_division)
        expect(enrollment_period2).to_not be_valid
      end

      it 'does not allow start_date to be equal to end_date' do
        start_date = 3.days.ago
        enrollment_period2 = build(:enrollment_period, start_date: start_date, end_date: start_date, administrative_division: administrative_division)
        expect(enrollment_period2).to_not be_valid
      end

      it 'allows start_date to be before end_date' do
        enrollment_period2 = build(:enrollment_period, start_date: 3.days.ago, end_date: 2.days.ago, administrative_division: administrative_division)
        expect(enrollment_period2).to be_valid
      end

      it 'allows start date to be the end of another enrollment period' do
        enrollment_period2 = build(:enrollment_period, start_date: enrollment_period.end_date, end_date: 2.days.ago, administrative_division: administrative_division)
        expect(enrollment_period2).to be_valid
      end

      it 'allows end date to be the start of another enrollment period' do
        enrollment_period2 = build(:enrollment_period, start_date: 80.days.ago, end_date: enrollment_period.start_date, administrative_division: administrative_division)
        expect(enrollment_period2).to be_valid
      end

      it 'allows overlapping start and end dates if enrollment period is in different regions' do
        expect(build(:enrollment_period, start_date: 5.days.ago, end_date: 5.days.from_now, administrative_division: another_administrative_division)).to be_valid
      end
    end
  end
end
