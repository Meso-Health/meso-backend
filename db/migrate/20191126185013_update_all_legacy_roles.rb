class UpdateAllLegacyRoles < ActiveRecord::Migration[5.0]
  def change
    User.where(role: 'card_room_worker').update_all(role: 'receptionist')
    User.where(role: 'claims_preparer').update_all(role: 'claims_officer')
    User.where(role: 'facility_head').update_all(role: 'facility_director')
    User.where(role: 'provider').update_all(role: 'claims_officer')
    User.where(role: 'enrollment_worker').update_all(role: 'enrollment_officer')
  end
end
