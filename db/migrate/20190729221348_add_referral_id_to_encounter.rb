class AddReferralIdToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_reference :encounters, :referral, type: :uuid, foreign_key: { to_table: :referrals }
  end
end
