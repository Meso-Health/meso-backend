class CreateIssuedIds < ActiveRecord::Migration[5.0]
  def change
    create_table :issued_ids, id: false do |t|
      t.string :id, limit: 9, primary_key: true, null: false

      t.timestamps
    end
  end
end
