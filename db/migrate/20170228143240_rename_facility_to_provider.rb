class RenameFacilityToProvider < ActiveRecord::Migration[5.0]
  def change
    rename_table :facilities, :providers
    rename_column :billables, :facility_id, :provider_id
    rename_column :encounters, :facility_id, :provider_id
    rename_column :identification_events, :facility_id, :provider_id
    rename_column :members, :facility_id, :provider_id
    rename_column :users, :facility_id, :provider_id
  end
end
