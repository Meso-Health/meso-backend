class AddSubvillageAndVillageToHousehold < ActiveRecord::Migration[5.0]
  def change
    add_column :households, :subvillage, :string, null: false
    add_column :households, :village, :string, null: false
  end
end
