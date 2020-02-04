class ChangeProviderCapitationFeeToNullable < ActiveRecord::Migration[5.0]
  def change
    change_column_null :providers, :capitation_fee, true
  end
end
