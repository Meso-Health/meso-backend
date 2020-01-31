class RemovePreferredContactFieldsFromMembers < ActiveRecord::Migration[5.0]
  def change
    remove_column :members, :preferred_contact, :string
    remove_column :members, :preferred_contact_other, :string
  end
end
