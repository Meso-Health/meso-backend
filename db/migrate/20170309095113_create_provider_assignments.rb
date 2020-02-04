class CreateProviderAssignments < ActiveRecord::Migration[5.0]
  def change
    create_table :provider_assignments do |t|
      t.references :member, type: :uuid, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: true
      t.timestamp :starts_at, null: false
      t.timestamp :ends_at
      t.string :start_reason, null: false
      t.string :end_reason

      t.timestamps
    end
  end
end
