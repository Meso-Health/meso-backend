class AddArchivedFieldsToMember < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :archived_at, :datetime
    add_column :members, :archived_reason, :string
  end
end
