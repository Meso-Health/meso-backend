class CreateLabResults < ActiveRecord::Migration[5.0]
  def change
    create_table :lab_results, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :encounter_item, type: :uuid, foreign_key: true, null: false
      t.string :result, null: false

      t.timestamps
    end

    add_column :billables, :requires_lab_result, :boolean, null: false, default: false
  end
end
