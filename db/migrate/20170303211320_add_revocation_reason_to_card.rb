class AddRevocationReasonToCard < ActiveRecord::Migration[5.0]
  def change
    add_column :cards, :revocation_reason, :string
  end
end
