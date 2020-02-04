class ChangeContractedDefaultToTrueOnProvider < ActiveRecord::Migration[5.0]
  def up
    change_column_default :providers, :contracted, true
    Provider.update_all(contracted: true)
  end

  def down
    change_column_default :providers, :contracted, false
    Provider.update_all(contracted: false)
  end
end
