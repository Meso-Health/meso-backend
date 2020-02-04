class CreatePilotRegionTable < ActiveRecord::Migration[5.0]
  def change
    create_table :pilot_regions do |t|
      t.references :administrative_division, null: false
      t.timestamps
    end
  end
end
