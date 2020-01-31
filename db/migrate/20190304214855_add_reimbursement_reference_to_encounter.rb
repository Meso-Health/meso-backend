class AddReimbursementReferenceToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_reference :encounters, :reimbursement, type: :uuid, foreign_key: true
  end
end
