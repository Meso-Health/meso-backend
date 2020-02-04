class AddMergedFromMemberIdToMember < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :merged_from_member_id, :uuid
  end
end
