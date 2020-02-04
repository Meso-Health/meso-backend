class ChangeStartEndDateOnEnrollmentPeriodToNotNull < ActiveRecord::Migration[5.0]
  def up
    change_column_null :enrollment_periods, :start_date, false
    change_column_null :enrollment_periods, :end_date, false
  end

  def down
    change_column_null :enrollment_periods, :start_date, true
    change_column_null :enrollment_periods, :end_date, true
  end
end
