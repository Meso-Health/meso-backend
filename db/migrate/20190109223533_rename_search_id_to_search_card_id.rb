class RenameSearchIdToSearchCardId < ActiveRecord::Migration[5.0]
  def up
    IdentificationEvent.where(search_method: 'search_id').update_all(search_method: 'search_card_id')
  end

  def down
    IdentificationEvent.where(search_method: 'search_card_id').update_all(search_method: 'search_id')
  end
end
