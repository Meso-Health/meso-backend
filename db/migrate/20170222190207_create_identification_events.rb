class CreateIdentificationEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :identification_events, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.datetime :occurred_at, null: false
      t.references :facility, foreign_key: true, null: false
      t.references :member, type: :uuid, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.boolean :accepted, null: false
      t.string :search_method, null: false
      t.boolean :photo_verified, null: false

      t.timestamps
    end
  end
end
