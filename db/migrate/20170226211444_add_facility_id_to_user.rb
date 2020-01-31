class AddFacilityIdToUser < ActiveRecord::Migration[5.0]
  def change
    add_belongs_to :users, :facility, foreign_key: true
  end
end
