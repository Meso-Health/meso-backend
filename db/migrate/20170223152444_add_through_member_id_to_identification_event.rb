class AddThroughMemberIdToIdentificationEvent < ActiveRecord::Migration[5.0]
  def change
    add_reference :identification_events, :through_member, type: :uuid, foreign_key: {to_table: :members}
  end
end
