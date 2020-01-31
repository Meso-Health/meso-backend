class AddClaimIdIndexToEncounters < ActiveRecord::Migration[5.0]
  def change
    add_index :encounters, :claim_id
  end
end
