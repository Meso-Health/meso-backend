class RemoveProviderIdFromBillableAndRemoveDuplicates < ActiveRecord::Migration[5.0]
  def up
    # Loop through billables and detect which billables have the same name.
    Billable.includes(:price_schedules).all.each do |billable|
      # Grab the billables with a matching billable attributes
      matching_billables = Billable.where(
        name: billable.name,
        composition: billable.composition,
        type: billable.type,
        unit: billable.unit,
        accounting_group: billable.accounting_group
      )
  
      # Arbitarily choose the first billable as the one to keep.
      billable_to_keep = matching_billables.order('provider_id').first
      # For the rest of the billables, make sure those price schedules' billable_id points to the first billable.
      duplicate_billables = matching_billables.where.not(id: billable_to_keep.id)
      
      duplicate_billables.each do |billable|
        # Make sure all those price schedules now point to the billable_to_keep.
        billable.price_schedules.update_all(billable_id: billable_to_keep.id)
      end
      # Mark all duplicate billables to inactive.
      duplicate_billables.update_all(active: false)
    end

    remove_reference :billables, :provider
  end

  def down
    add_reference :billables, :provider, foreign_key: :true
    # It is super tricky to make this migration reversible AND return the data to the state it was before.
    # So right now, if we need to reverse this migration for any reason, billable update is scary.
    # Scoping decision: Let's just make the schema reversible in schema only.
    Billable.update_all(provider_id: Provider.first.id)

    change_column_null :billables, :provider_id, false
  end
end
