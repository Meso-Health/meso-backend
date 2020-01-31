class AddUniqueIndexToPayments < ActiveRecord::Migration[5.0]
  def change
    add_index :payments, [:provider_id, :type, :effective_date], unique: true 
  end
end
