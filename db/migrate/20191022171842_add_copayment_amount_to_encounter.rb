class AddCopaymentAmountToEncounter < ActiveRecord::Migration[5.0]
  def up
    add_column :encounters, :copayment_amount, :integer, default: 0, null: false
    encounters_with_copayment = Encounter.where(copayment_paid: true)
    encounters_with_copayment.where('occurred_at < ?', Time.parse("2019-07-01")).update_all("copayment_amount=1000")
    encounters_with_copayment.where('occurred_at >= ?', Time.parse("2019-07-01")).update_all("copayment_amount=10000")

    remove_column :encounters, :copayment_paid
  end

  def down
    remove_column :encounters, :copayment_amount
    add_column :encounters, :copayment_paid, :boolean
  end
end