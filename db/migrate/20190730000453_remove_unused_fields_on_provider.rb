class RemoveUnusedFieldsOnProvider < ActiveRecord::Migration[5.0]
  def change
    remove_column :providers, :country_code, :string
    remove_column :providers, :latitude, :decimal
    remove_column :providers, :longitude, :decimal
    remove_column :providers, :capitation_fee, :float
  end
end
