class RemoveDragonflyUidFromHouseholdAndMember < ActiveRecord::Migration[5.0]
  def change
    remove_column :households, :photo_uid
    remove_column :members, :photo_uid
    remove_column :members, :national_id_photo_uid
  end
end
