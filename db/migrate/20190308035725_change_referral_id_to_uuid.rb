class ChangeReferralIdToUuid < ActiveRecord::Migration[5.0]
  def change
    # Followed some instructions in this post: http://www.madebyloren.com/posts/migrating-to-uuids-as-primary-keys
    add_column :referrals, :uuid, :uuid, default: "gen_random_uuid()", null: false
    remove_column :referrals, :id
    rename_column :referrals, :uuid, :id
    execute "ALTER TABLE referrals ADD PRIMARY KEY (id);"
  end
end
