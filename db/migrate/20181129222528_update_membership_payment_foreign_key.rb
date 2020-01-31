class UpdateMembershipPaymentForeignKey < ActiveRecord::Migration[5.0]
  def change
    remove_foreign_key :household_enrollment_records, :membership_payments
    remove_column :household_enrollment_records, :membership_payment_id, :uuid

    # Delete all MembershipPayments because they are meaningless anyway at this point.
    MembershipPayment.delete_all

    add_reference :membership_payments, :household_enrollment_record, type: :uuid, foreign_key: true, null: false
  end
end
