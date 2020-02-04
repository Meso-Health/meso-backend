class RemoveNotNullFromMembersFacilityId < ActiveRecord::Migration[5.0]
  def change
    change_column_null :members, :facility_id, true
  end
end
