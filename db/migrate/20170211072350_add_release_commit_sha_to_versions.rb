class AddReleaseCommitShaToVersions < ActiveRecord::Migration[5.0]
  def change
    add_column :versions, :release_commit_sha, :string, null: false
  end
end
