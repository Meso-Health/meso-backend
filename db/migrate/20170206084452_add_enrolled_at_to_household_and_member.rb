class AddEnrolledAtToHouseholdAndMember < ActiveRecord::Migration[5.0]
  def change
    add_column :households, :enrolled_at, :datetime
    add_column :members, :enrolled_at, :datetime

    Household.update_all('enrolled_at = created_at')
    Member.update_all('enrolled_at = created_at')

    change_column_null :households, :enrolled_at, false
    change_column_null :members, :enrolled_at, false
  end
end
