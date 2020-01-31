class ChangeReimbursementTotalToInteger < ActiveRecord::Migration[5.0]
  def up
    change_column :reimbursements, :total, 'integer USING CAST(total AS integer)'
  end

  def down
    change_column :reimbursements, :total, :string
  end
end
