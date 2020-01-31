class AddInvalidAttributesToMember < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :invalid_attributes, :jsonb, default: {}, null: false
  end
end
