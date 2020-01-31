class ChangeBillablePriceToDecimal < ActiveRecord::Migration[5.0]
  def up
    change_column :billables, :price, :decimal, :precision => 10, :scale => 2
  end

  def down
    change_column :billables, :price, :integer
  end
end
