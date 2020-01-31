class RenameAdditionalMembersFeeToQualifyingBeneficiaries < ActiveRecord::Migration[5.0]
  def change
    rename_column :membership_payments, :additional_members_fee, :qualifying_beneficiaries_fee
  end
end
