class AddCopaymentPaidFieldToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :copayment_paid, :boolean
  end
end
