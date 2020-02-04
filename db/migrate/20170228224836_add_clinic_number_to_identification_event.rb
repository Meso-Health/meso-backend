class AddClinicNumberToIdentificationEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :identification_events, :clinic_number, :integer
    add_column :identification_events, :clinic_number_type, :string
  end
end
