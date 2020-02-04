class ChangeUniqueIndexOnUserToPartialOnRole < ActiveRecord::Migration[5.0]
  def up
    remove_index :users, :username
    add_index :users, :username, unique: true, where: "role IN ('admin', 'clinic')"
  end

  def down
    remove_index :users, :username
    add_index :users, :username, unique: true
  end
end
