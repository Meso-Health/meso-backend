class AddTypeToProvider < ActiveRecord::Migration[5.0]
  def change
    add_column :providers, :provider_type, :string, default: 'unclassified', null: false
  end
end
