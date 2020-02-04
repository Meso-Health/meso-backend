class ChangeClinicUserRoleToProvider < ActiveRecord::Migration[5.0]
  def change
    remove_index :users, :username
    add_index :users, :username, unique: true, where: "role IN ('admin', 'provider')"
  end
end
