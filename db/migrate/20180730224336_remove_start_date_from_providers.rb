class RemoveStartDateFromProviders < ActiveRecord::Migration[5.0]
  def change
    remove_column :providers, :start_date, :date
  end
end
