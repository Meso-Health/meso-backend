class AddDischargeDateToEncounters < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :discharge_date, :date
  end
end
