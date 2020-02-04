class AddSecurityPinToProvider < ActiveRecord::Migration[5.0]
  def change
    add_column :providers, :security_pin, :string, limit: 4, null: false, default: '0000'
  end
end
