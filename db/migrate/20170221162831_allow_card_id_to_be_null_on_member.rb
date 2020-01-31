class AllowCardIdToBeNullOnMember < ActiveRecord::Migration[5.0]
  def change
    change_column_null :members, :card_id, true
  end
end
