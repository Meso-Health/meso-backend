class AddRevokedAtToCardId < ActiveRecord::Migration[5.0]
  def change
    add_column :card_ids, :revoked_at, :timestamp
  end
end
