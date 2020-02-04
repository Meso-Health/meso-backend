class RemoveProviderIdFromEnrollmentPeriod < ActiveRecord::Migration[5.0]
  def change
    remove_column :enrollment_periods, :provider_id, :int
    remove_column :enrollment_periods, :provider_assignment_starts_at, :datetime
    remove_column :enrollment_periods, :provider_assignment_start_reason, :datetime
  end
end
