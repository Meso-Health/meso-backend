class CreateAdministrativeDivisions < ActiveRecord::Migration[5.0]
  def change
    create_table :administrative_divisions do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.string :code
      t.references :parent, index: true, foreign_key: { to_table: :administrative_divisions }

      t.timestamps
    end

    add_reference :users, :administrative_division, foreign_key: true
    add_reference :providers, :administrative_division, foreign_key: true
    add_reference :households, :administrative_division, foreign_key: true
    add_reference :household_enrollment_records, :administrative_division, foreign_key: true, index: { name: 'index_household_enrollment_records_on_a_d_id' }
  end
end
