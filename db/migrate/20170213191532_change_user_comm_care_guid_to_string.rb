class ChangeUserCommCareGuidToString < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :comm_care_mobile_worker_id, :string
  end
end
