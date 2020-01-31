class ChangeBirthdayAccuracyFormat < ActiveRecord::Migration[5.0]
  def change
    Member.where(birthday_accuracy: 'year').update_all(birthday_accuracy: 'Y')
    Member.where(birthday_accuracy: 'month').update_all(birthday_accuracy: 'M')
    Member.where(birthday_accuracy: 'day').update_all(birthday_accuracy: 'D')

    change_table :members do |t|
      t.change :birthday_accuracy, :string, limit: 1
    end
  end
end
