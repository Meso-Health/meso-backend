class ChangeIdentificationEventsAcceptedAndPhotoVerifiedToNullable < ActiveRecord::Migration[5.0]
  def change
    change_column_null :identification_events, :accepted, true
    change_column_null :identification_events, :photo_verified, true
  end
end
