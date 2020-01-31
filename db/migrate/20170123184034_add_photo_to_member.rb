class AddPhotoToMember < ActiveRecord::Migration[5.0]
  def change
    add_column :members, :photo_uid, :string
    add_column :members, :photo_name, :string
  end
end
