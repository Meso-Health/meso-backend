class RemoveProviderAssignmentsTable < ActiveRecord::Migration[5.0]
  class ProviderAssignment < ActiveRecord::Base
    belongs_to :member
  end

  def up
    # Any member that has a ProviderAssignment.ends_at / ends_reason set will
    # migrate over to the member.archived_at/archival_reason fields
    PaperTrail.without_versioning do
      ProviderAssignment.where.not(end_reason: nil).each do |pa|
        member = pa.member
        member.archived_at = pa.ends_at
        member.archived_reason = pa.end_reason
        member.save
      end
    end

    drop_table :provider_assignments do |t|
      t.references :member, type: :uuid, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: true
      t.timestamp :starts_at, null: false
      t.timestamp :ends_at
      t.string :start_reason, null: false
      t.string :end_reason

      t.timestamps
    end
  end

  def down
    create_table :provider_assignments do |t|
      t.references :member, type: :uuid, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: true
      t.timestamp :starts_at, null: false
      t.timestamp :ends_at
      t.string :start_reason, null: false
      t.string :end_reason

      t.timestamps
    end
  end
end
