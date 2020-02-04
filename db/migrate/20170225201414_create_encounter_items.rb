class CreateEncounterItems < ActiveRecord::Migration[5.0]
  def change
    create_table :encounter_items, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :encounter, type: :uuid, foreign_key: true, null: false
      t.references :billable, type: :uuid, foreign_key: true, null: false
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end
  end
end
