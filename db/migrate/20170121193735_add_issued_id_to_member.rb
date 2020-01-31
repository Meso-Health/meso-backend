class AddIssuedIdToMember < ActiveRecord::Migration[5.0]
  def change
    truncate :members
    add_column :members, :issued_id, :string, limit: 9, null: false
    add_index :members, :issued_id, unique: true
    add_foreign_key :members, :issued_ids, column: :issued_id
  end
end
