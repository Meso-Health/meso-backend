class RemovePhoneNumberLimitFromMembers < ActiveRecord::Migration[5.0]
  def up
    change_column :members, :phone_number, :string, limit: nil
  end

  def down
    change_column :members, :phone_number, :string, limit: 10
  end
end
