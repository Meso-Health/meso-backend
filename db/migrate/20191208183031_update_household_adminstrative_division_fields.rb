class UpdateHouseholdAdminstrativeDivisionFields < ActiveRecord::Migration[5.0]
  def change
    change_column_null :households, :administrative_division_id, false
    remove_column :households, :village, :string
    remove_column :households, :subvillage, :string
  end
end
