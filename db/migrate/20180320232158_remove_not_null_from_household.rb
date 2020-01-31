class RemoveNotNullFromHousehold < ActiveRecord::Migration[5.0]
  def change
    change_column :households, :latitude, :decimal, null: true
    change_column :households, :longitude, :decimal, null: true
    change_column_null :households, :village, true
    change_column_null :households, :subvillage, true
  end
end
