class RenameBillableDepartmentToAccountingGroup < ActiveRecord::Migration[5.0]
  def up
    rename_column :billables, :department, :accounting_group
    # Set these to nil so validations on Billable won't fail. accounting_group will be backfilled in a 1-off script
    Billable.update_all(accounting_group: nil)
  end

  def down
    rename_column :billables, :accounting_group, :department
  end
end
