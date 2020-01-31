class RenameReturnReasonToAdjudicationReasonOnEncounter < ActiveRecord::Migration[5.0]
  def change
    rename_column :encounters, :return_reason, :adjudication_reason
  end
end
