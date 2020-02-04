class AddSourceToVersion < ActiveRecord::Migration[5.0]
  def change
    add_column :versions, :source, :string
  end
end
