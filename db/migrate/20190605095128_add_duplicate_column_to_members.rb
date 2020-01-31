class AddDuplicateColumnToMembers < ActiveRecord::Migration[5.0]
  def change
    add_reference :members, :original_member, type: :uuid, foreign_key: {to_table: :members}
  end
end
