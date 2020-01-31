class RemoveAbsenceReasonFromMembers < ActiveRecord::Migration[5.0]
  def change
    remove_column :members, :absence_reason, :string
  end
end
