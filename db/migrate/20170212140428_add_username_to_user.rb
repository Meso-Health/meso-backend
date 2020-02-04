class AddUsernameToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :username, :string
    User.update_all("username = replace(lower(name), ' ', '_')")
    change_column_null :users, :username, false
  end
end
