class AddBirthdayToMember < ActiveRecord::Migration[5.0]
  def change
    truncate :members
    change_table :members do |t|
      t.date :birthday, null: false
      t.string :birthday_accuracy, null: false
    end
  end
end
