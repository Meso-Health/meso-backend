class AddSubmissionStateToEncounters < ActiveRecord::Migration[5.0]
  def up
    add_column :encounters, :submission_state, :string
    Encounter.update_all(submission_state: 'submitted')
    change_column_null :encounters, :submission_state, false

    change_column_null :encounters, :adjudication_state, true
    change_column_default :encounters, :adjudication_state, nil
  end

  def down
    remove_column :encounters, :submission_state, :string

    change_column_default :encounters, :adjudication_state, 'pending'
    change_column_null :encounters, :adjudication_state, false
  end
end
