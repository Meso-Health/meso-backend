class ChangeAdministrativeDivisionIdToNullableOnProvider < ActiveRecord::Migration[5.0]
  def change
    PaperTrail.without_versioning do
      # Create an admin division for Rwibaale
      ad = AdministrativeDivision.new
      ad.name = "Rwibaale"
      ad.level = "parish"
      ad.save

      # Assign all providers an administrative division in order for this migration to work.
      # (should only be 1 for Uganda)
      Provider.update_all(administrative_division_id: ad.id) 
    end

    change_column_null :providers, :administrative_division_id, false
  end
end
