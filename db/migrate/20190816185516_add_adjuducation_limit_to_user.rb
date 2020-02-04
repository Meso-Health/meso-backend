class AddAdjuducationLimitToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :adjudication_limit, :integer
  end
end
