class AddDiagnosesGroupIdToProvider < ActiveRecord::Migration[5.0]
  def change
    add_reference :providers, :diagnoses_group, foreign_key: true
  end
end
