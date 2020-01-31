class FixRukigaSpelling < ActiveRecord::Migration[5.0]
  def up
    Member.where(preferred_language: 'riukiga').update_all(preferred_language: 'rukiga')
  end

  def down
    Member.where(preferred_language: 'rukiga').update_all(preferred_language: 'riukiga')
  end
end
