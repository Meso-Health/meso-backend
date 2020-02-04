class ChangeMembershipPaymentFields < ActiveRecord::Migration[5.0]
  def change
    remove_column :membership_payments, :total, :integer

    add_column :membership_payments, :annual_contribution_fee, :integer, default: 0, null: false
    add_column :membership_payments, :additional_members_fee, :integer, default: 0, null: false
    add_column :membership_payments, :registration_fee, :integer, default: 0, null: false
    add_column :membership_payments, :penalty_fee, :integer, default: 0, null: false
    add_column :membership_payments, :other_fee, :integer, default: 0, null: false
    add_column :membership_payments, :card_replacement_fee, :integer, default: 0, null: false
  end
end
