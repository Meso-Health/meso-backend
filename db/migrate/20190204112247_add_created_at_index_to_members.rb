class AddCreatedAtIndexToMembers < ActiveRecord::Migration[5.0]
  def change
    add_index :members, :created_at
  end
end
