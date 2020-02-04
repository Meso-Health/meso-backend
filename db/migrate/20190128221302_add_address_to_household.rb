class AddAddressToHousehold < ActiveRecord::Migration[5.0]
  def change
    add_column :households, :address, :string
  end
end
