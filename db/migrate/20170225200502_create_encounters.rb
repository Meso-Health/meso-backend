class CreateEncounters < ActiveRecord::Migration[5.0]
  def change
    create_table :encounters, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :facility, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.references :member, type: :uuid, foreign_key: true, null: false
      t.references :identification_event, type: :uuid, foreign_key: true, null: false
      t.timestamp :occurred_at, null: false

      t.timestamps
    end
  end
end
