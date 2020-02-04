class CreateEnrollmentRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :enrollment_records, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.json :payload, null: false
      t.json :attachments, null: false, default: {}

      t.timestamps
    end
  end
end
