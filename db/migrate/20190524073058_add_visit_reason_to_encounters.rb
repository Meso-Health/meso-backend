class AddVisitReasonToEncounters < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :visit_reason, :string
  end
end
