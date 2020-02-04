class RevertRemoveNotNullFromHousehold < ActiveRecord::Migration[5.0]
  def change
    change_column :households, :latitude, :decimal, null: false, precision: 10, scale: 6
    change_column :households, :longitude, :decimal, null: false, precision: 10, scale: 6
    change_column_null :households, :village, false
    change_column_null :households, :subvillage, false
  end
end
