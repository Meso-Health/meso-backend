class ReplaceMedicalRecordNumberWithJsonField < ActiveRecord::Migration[5.0]
  def up
    add_column :members, :medical_record_numbers, :jsonb, default: {}
    # Fill out existing jsonb field with { 'primary': member.medical_record_number }
    # pulled code from this example: https://github.com/galahq/gala/blob/731a50d0daadb76b4d38e9cdf48fe37599844118/db/migrate/20171030185254_add_description_and_url_to_libraries.rb#L11
    Member.update_all(%(medical_record_numbers = ('{"primary": "'||medical_record_number||'"}')::jsonb))
    remove_column :members, :medical_record_number
    add_index :members, :medical_record_numbers, using: :gin
  end

  def down
    add_column :members, :medical_record_number, :string
    Member.update_all("medical_record_number = medical_record_numbers->>'primary'")
    remove_index :members, :medical_record_numbers
    remove_column :members, :medical_record_numbers
  end
end
