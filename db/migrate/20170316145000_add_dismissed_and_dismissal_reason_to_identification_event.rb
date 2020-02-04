class AddDismissedAndDismissalReasonToIdentificationEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :identification_events, :dismissed, :boolean, default: false, null: false
    add_column :identification_events, :dismissal_reason, :string
  end
end
