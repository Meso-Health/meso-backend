class ChangeAdministrativeTypeToDivisionType < ActiveRecord::Migration[5.0]
  def change
    rename_column :administrative_divisions, :type, :level
  end
end
