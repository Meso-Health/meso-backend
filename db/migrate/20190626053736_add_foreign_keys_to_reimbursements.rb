class AddForeignKeysToReimbursements < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :reimbursements, :providers
    add_foreign_key :reimbursements, :users
  end
end
