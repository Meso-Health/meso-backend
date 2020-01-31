class AddVisitTypeToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :visit_type, :string
  end
end
