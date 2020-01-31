class AddCoveragePeriodAndAdministrativeDivisionToEnrollmentPeriod < ActiveRecord::Migration[5.0]
  def change
    # First add the columns as nullable.
    add_column :enrollment_periods, :coverage_start_date, :date
    add_column :enrollment_periods, :coverage_end_date, :date
    add_reference :enrollment_periods, :administrative_division

    # Backfill them for now to be the same as the enrollment period dates.
    # Let's pick the first administrative division for now (i.e. Tigray region)
    EnrollmentPeriod.update_all(
      "coverage_start_date = start_date, coverage_end_date = end_date, administrative_division_id = 1",
    )

    change_column_null :enrollment_periods, :coverage_start_date, false
    change_column_null :enrollment_periods, :coverage_end_date, false
    change_column_null :enrollment_periods, :administrative_division_id, false
  end
end
