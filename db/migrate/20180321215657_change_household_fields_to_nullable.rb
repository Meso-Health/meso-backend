class ChangeHouseholdFieldsToNullable < ActiveRecord::Migration[5.0]
  def change
    change_column_null :households, :latitude, true
    change_column_null :households, :longitude, true
    change_column_null :households, :village, true
    change_column_null :households, :subvillage, true
  end
end
