class CreateReferrals < ActiveRecord::Migration[5.0]
  def change
    create_table :referrals do |t|
      t.string :receiving_facility, null: false
      t.string :reason, null: false
      t.string :number
      t.references :encounter, type: :uuid, foreign_key: true, null: false
    end
  end
end
