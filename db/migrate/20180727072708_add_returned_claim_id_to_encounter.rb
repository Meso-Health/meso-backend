class AddReturnedClaimIdToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_reference :encounters, :returned_claim, type: :uuid, foreign_key: { to_table: :encounters }
  end
end
