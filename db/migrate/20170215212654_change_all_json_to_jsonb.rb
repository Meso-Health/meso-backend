class ChangeAllJsonToJsonb < ActiveRecord::Migration[5.0]
  def up
    change_column :enrollment_records, :payload, 'jsonb USING CAST(payload AS jsonb)'
    change_column :enrollment_records, :attachments, 'jsonb USING CAST(attachments AS jsonb)', default: {}
    change_column :enrollment_records, :extra_context, 'jsonb USING CAST(extra_context AS jsonb)', default: {}
  end

  def down
    change_column :enrollment_records, :payload, 'json USING CAST(payload AS json)'
    change_column :enrollment_records, :attachments, 'json USING CAST(attachments AS json)', default: {}
    change_column :enrollment_records, :extra_context, 'json USING CAST(extra_context AS json)', default: {}
  end
end
