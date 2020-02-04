class AddPriceScheduleFieldsToEncounterItem < ActiveRecord::Migration[5.0]
  def up
    add_reference :encounter_items, :price_schedule, type: :uuid, foreign_key: :true
    add_column :encounter_items, :price_schedule_issued, :boolean, default: false, null: false

    Encounter.all.each do |encounter|
      provider_id = encounter.provider_id
      encounter.encounter_items.each do |encounter_item|
        price_schedule = PriceSchedule.find_by(
          provider_id: provider_id,
          billable_id: encounter_item.billable_id
        )
        encounter_item.update_column(:price_schedule_id, price_schedule.id)
      end
    end

    change_column_null :encounter_items, :price_schedule_id, false
  end

  def down
    remove_column :encounter_items, :price_schedule_id
    remove_column :encounter_items, :price_schedule_issued
  end
end
