class CreateIssuedIdBatches < ActiveRecord::Migration[5.0]
  def change
    create_table :issued_id_batches do |t|
      t.string :prefix
      t.text :reason, null: false

      t.timestamps
    end

    change_table :issued_ids do |t|
      t.references :issued_id_batch, foreign_key: true, null: false
    end
  end
end
