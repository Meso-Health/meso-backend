class AddPreferredLanguageAndContactToMember < ActiveRecord::Migration[5.0]
  def change
    change_table :members do |t|
      t.string :preferred_language
      t.string :preferred_language_other
      t.string :preferred_contact
      t.string :preferred_contact_other
    end

    Member.update_all(preferred_language: 'rutooro', preferred_contact: 'phone')
  end
end
