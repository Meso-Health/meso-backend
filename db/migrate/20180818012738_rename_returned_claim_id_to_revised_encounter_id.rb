class RenameReturnedClaimIdToRevisedEncounterId < ActiveRecord::Migration[5.0]
  def change
    rename_column :encounters, :returned_claim_id, :revised_encounter_id
  end
end
