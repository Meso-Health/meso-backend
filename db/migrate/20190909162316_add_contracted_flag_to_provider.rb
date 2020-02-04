class AddContractedFlagToProvider < ActiveRecord::Migration[5.0]
  def change
    add_column :providers, :contracted, :boolean, default: false, null: false
  end
end