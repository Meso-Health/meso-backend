class DropProviderIdOnMember < ActiveRecord::Migration[5.0]
  def change
    remove_column :members, :provider_id
  end
end
