class AddAdjudicationReasonCategoryToEncounter < ActiveRecord::Migration[5.0]
  def change
    add_column :encounters, :adjudication_reason_category, :string
    rename_column :encounters, :adjudication_reason, :adjudication_comment
  end
end
