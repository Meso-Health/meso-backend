class UpdateReimbursementPaymentMethod < ActiveRecord::Migration[5.0]
  def change
    remove_column :reimbursements,:transfer_number, :string
    remove_column :reimbursements,:transfer_date, :date
    remove_column :reimbursements,:receipt_date, :date
    remove_column :reimbursements,:receipt_number, :string
    add_column :reimbursements, :payment_date, :date
    add_column :reimbursements, :payment_field, :jsonb
  end
end
