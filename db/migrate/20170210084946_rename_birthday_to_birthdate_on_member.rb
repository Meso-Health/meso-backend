class RenameBirthdayToBirthdateOnMember < ActiveRecord::Migration[5.0]
  def change
    rename_column :members, :birthday, :birthdate
    rename_column :members, :birthday_accuracy, :birthdate_accuracy
  end
end
