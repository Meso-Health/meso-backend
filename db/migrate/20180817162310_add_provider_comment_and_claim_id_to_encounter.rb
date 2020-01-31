class AddProviderCommentAndClaimIdToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :provider_comment, :text
    add_column :encounters, :claim_id, :text
    # I am assuming all encounters in the system are all new claims.
    Encounter.all.each do |encounter|
      encounter.update_column(:claim_id, encounter.id)
    end

    change_column_null :encounters, :claim_id, false
  end
end
