class ChangeIdentificationEventsDismissedToNullable < ActiveRecord::Migration[5.0]
  def change
        change_column_null :identification_events, :dismissed, true
  end
end
