class AddAuditFieldsToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :audited_at, :datetime
    add_reference :encounters, :auditor, null: true, foreign_key: { to_table: :users }
  end
end
