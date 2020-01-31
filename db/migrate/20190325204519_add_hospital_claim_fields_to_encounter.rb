class AddHospitalClaimFieldsToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :custom_reimbursal_amount, :integer
    add_column :encounters, :inbound_referral_date, :date
  end
end
