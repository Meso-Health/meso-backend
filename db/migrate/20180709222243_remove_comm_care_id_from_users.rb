class RemoveCommCareIdFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :comm_care_mobile_worker_id, :string
  end
end
