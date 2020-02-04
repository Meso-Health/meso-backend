class ChangeEncountersIdentificationEventToNullable < ActiveRecord::Migration[5.0]
  def change
    change_column_null :encounters, :identification_event_id, true
  end
end
