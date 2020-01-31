class CreateMembers < ActiveRecord::Migration[5.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :members, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :facility, foreign_key: true, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
