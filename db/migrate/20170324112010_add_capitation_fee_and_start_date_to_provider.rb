class AddCapitationFeeAndStartDateToProvider < ActiveRecord::Migration[5.0]
  def change
    add_column :providers, :capitation_fee, :float, default: 3600, null: false
    add_column :providers, :start_date, :date, default: '2017-03-01', null: false
    change_column_default :providers, :capitation_fee, nil
    change_column_default :providers, :start_date, nil
  end
end
