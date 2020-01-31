require 'rails_helper'

RSpec.describe PriceSchedule, type: :model do
  describe 'Validation' do
    let(:provider) { create(:provider) }
    let(:billable) { create(:billable) }

    describe 'price' do
      it 'allows zero as the price' do
        price_schedule = build(:price_schedule, provider: provider, billable: billable, price: 0)
        expect(price_schedule).to be_valid
      end

      it 'allows positive prices' do
        price_schedule = build(:price_schedule, provider: provider, billable: billable, price: 10)
        expect(price_schedule).to be_valid
      end

      it 'does not allow negative prices' do
        price_schedule = build(:price_schedule, provider: provider, billable: billable, price: -10)
        expect(price_schedule).to_not be_valid
      end
    end

    describe 'previous_price_schedule_id' do
      it 'allows nil previous_price_schedule_id if first price schedule created for that billable' do
        price_schedule = build(:price_schedule, provider: provider, billable: billable, previous_price_schedule_id: nil)
        expect(price_schedule).to be_valid
      end

      it 'does not allow nil previous_price_schedule_id if price schedule already exists for that billable' do
        create(:price_schedule, provider: provider, billable: billable, issued_at: 10.days.ago)
        price_schedule = build(:price_schedule, provider: provider, billable: billable, previous_price_schedule_id: nil)
        expect(price_schedule).to_not be_valid
      end

      it 'allows non-nil previous_price_schedule_id if price schedule already exists for that billable' do
        old_price_schedule = create(:price_schedule, provider: provider, billable: billable, issued_at: 10.days.ago)
        price_schedule = build(:price_schedule, provider: provider, billable: billable, previous_price_schedule_id: old_price_schedule.id)
        expect(price_schedule).to be_valid
      end
    end

    describe 'billable' do
      it 'does not allow invalid billable_id' do
        price_schedule = build(:price_schedule, provider: provider, billable_id: SecureRandom.uuid, previous_price_schedule_id: nil)
        expect(price_schedule).to_not be_valid
      end
    end
  end

  describe '.active' do
    let(:active_billable) { create(:billable, active: true) }
    let(:inactive_billable) { create(:billable, active: false) }
    let(:provider1) { create(:provider) }
    let(:provider2) { create(:provider) }
    let(:price_schedule1) { create(:price_schedule, issued_at: 5.days.ago, billable: active_billable, provider: provider1) }
    let(:price_schedule2) { create(:price_schedule, issued_at: 3.days.ago, billable: active_billable, provider: provider1) }
    let(:price_schedule3) { create(:price_schedule, billable: inactive_billable, provider: provider1) }
    let(:price_schedule4) { create(:price_schedule, provider: provider2) }

    it 'selects latest issued price schedules for each active billable' do
      expect(PriceSchedule.active).to match_array([price_schedule2, price_schedule4])
    end
  end
end
