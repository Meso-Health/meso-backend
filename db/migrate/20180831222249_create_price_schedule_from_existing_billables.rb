class CreatePriceScheduleFromExistingBillables < ActiveRecord::Migration[5.0]
  def up
    PaperTrail.without_versioning do
      Billable.includes(:price_schedules).all.each do |billable|
        if billable.price_schedules.empty?
          PriceSchedule.create(
            provider_id: billable.provider_id,
            billable_id: billable.id,
            issued_at: Time.zone.now,
            price: billable.price
          )
        end
      end
    end
  end

  def down
    PriceSchedule.delete_all
  end
end
