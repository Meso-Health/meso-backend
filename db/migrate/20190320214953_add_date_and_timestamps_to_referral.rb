class AddDateAndTimestampsToReferral < ActiveRecord::Migration[5.0]
  def change
    add_timestamps :referrals, null: true
    add_column :referrals, :date, :date

    # This is the EPOCH time so the time set on these referrals
    # is not dependent on when we run the migration
    epoch_time = Time.zone.at(0)
    Referral.update_all(created_at: epoch_time, updated_at: epoch_time, date: epoch_time.to_date)
    change_column_null :referrals, :updated_at, false
    change_column_null :referrals, :created_at, false
    change_column_null :referrals, :date, false
  end
end
