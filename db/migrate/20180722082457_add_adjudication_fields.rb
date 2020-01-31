class AddAdjudicationFields < ActiveRecord::Migration[5.0]
  def change
    change_table :encounters do |t|
      t.string :adjudication_state, null: false, default: 'pending'
      t.references :adjudicator, null: true, foreign_key: { to_table: :users }
      t.datetime :adjudicated_at
      t.string :return_reason
    end
  end
end
