class RemoveInvalidAttributesFromMembers < ActiveRecord::Migration[5.0]
  def change
    remove_column :members, :invalid_attributes, :jsonb
  end
end
