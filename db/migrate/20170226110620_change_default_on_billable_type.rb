class ChangeDefaultOnBillableType < ActiveRecord::Migration[5.0]
  def change
    change_column_default :billables, :type, 'unspecified'
  end
end
