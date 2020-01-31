class DropAbsenteeOnHousehold < ActiveRecord::Migration[5.0]
  def change
    remove_column :households, :absentee
  end
end
