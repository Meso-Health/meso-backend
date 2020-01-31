class AddAttachmentsReferencesToHouseholdAndMember < ActiveRecord::Migration[5.0]
  def change
    rename_column :households, :photo_name, :photo_id
    change_column :households, :photo_id, :string, limit: 32, null: true
    Household.update_all('photo_id = NULL')
    add_foreign_key :households, :attachments, column: :photo_id

    rename_column :members, :photo_name, :photo_id
    change_column :members, :photo_id, :string, limit: 32, null: true
    Member.update_all('photo_id = NULL')
    add_foreign_key :members, :attachments, column: :photo_id

    rename_column :members, :national_id_photo_name, :national_id_photo_id
    change_column :members, :national_id_photo_id, :string, limit: 32, null: true
    Member.update_all('national_id_photo_id = NULL')
    add_foreign_key :members, :attachments, column: :national_id_photo_id
  end
end
