class CreateAttachments < ActiveRecord::Migration[5.0]
  def change
    create_table :attachments, id: :string, limit: 32 do |t|
      t.string :file_uid, null: false, index: {unique: true}
      t.string :file_name
      t.integer :file_width
      t.integer :file_height
      t.integer :file_size

      t.timestamps
    end
  end
end
