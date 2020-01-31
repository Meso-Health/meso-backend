class AddFingerprintsMetadataToIdentificationEvent < ActiveRecord::Migration[5.0]
  def change
  	add_column :identification_events, :fingerprints_verification_result_code, :integer, default: nil
  	add_column :identification_events, :fingerprints_verification_confidence, :float, default: nil
  	add_column :identification_events, :fingerprints_verification_tier, :string, default: nil
  end
end
