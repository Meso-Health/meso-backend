class RenameCardIdsToCards < ActiveRecord::Migration[5.0]
  def change
    rename_table :card_ids, :cards
    rename_table :card_id_batches, :card_batches
    rename_column :cards, :card_id_batch_id, :card_batch_id
  end
end
