class RenameIssuedIdTables < ActiveRecord::Migration[5.0]
  def change
    rename_column :members, :issued_id, :card_id

    rename_column :issued_ids, :issued_id_batch_id, :card_id_batch_id
    rename_table :issued_ids, :card_ids

    rename_table :issued_id_batches, :card_id_batches
  end
end
