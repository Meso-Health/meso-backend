class DropAbsenteeFromMember < ActiveRecord::Migration[5.0]
  def change
    remove_column :members, :absentee
  end
end
