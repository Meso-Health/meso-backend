class CreateEnrollmentPeriods < ActiveRecord::Migration[5.0]
  def change
    create_table :enrollment_periods do |t|
      t.date :start_date
      t.date :end_date
      t.datetime :provider_assignment_starts_at
      t.references :provider, foreign_key: true, null: false

      t.timestamps
    end
  end
end
