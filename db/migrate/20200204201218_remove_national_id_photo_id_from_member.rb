class RemoveNationalIdPhotoIdFromMember < ActiveRecord::Migration[5.1]
  def change
    remove_column :members, :national_id_photo_id
  end
end
