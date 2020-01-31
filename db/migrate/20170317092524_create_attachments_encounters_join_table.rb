class CreateAttachmentsEncountersJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :attachments_encounters do |t|
      t.references :attachment, type: :string, limit: 32, null: false, foreign_key: true, index: false
      t.references :encounter, type: :uuid, null: false, foreign_key: true, index: false
      t.index [:attachment_id, :encounter_id], unique: true
    end
  end
end
