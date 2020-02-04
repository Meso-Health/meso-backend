class AddProviderAssignmentStartReasonToEnrollmentPeriod < ActiveRecord::Migration[5.0]
  def change
    add_column :enrollment_periods, :provider_assignment_start_reason, :string
  end
end
