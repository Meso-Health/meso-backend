class ChangeMemberFields < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :membership_number, :string
    add_column :members, :medical_record_number, :string
    change_column_null :members, :household_id, true

    add_index :members, :membership_number
  end
end
