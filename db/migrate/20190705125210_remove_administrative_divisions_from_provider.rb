class RemoveAdministrativeDivisionsFromProvider < ActiveRecord::Migration[5.0]
  def change
    remove_column :providers, :administrative_divisions, :string
  end
end
