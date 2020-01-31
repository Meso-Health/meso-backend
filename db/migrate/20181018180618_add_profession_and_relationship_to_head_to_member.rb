class AddProfessionAndRelationshipToHeadToMember < ActiveRecord::Migration[5.0]
  def change
    change_table :members do |t|
      t.string :profession
      t.string :relationship_to_head
    end
  end
end
