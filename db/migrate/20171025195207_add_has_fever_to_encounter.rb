class AddHasFeverToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :has_fever, :boolean
  end
end
