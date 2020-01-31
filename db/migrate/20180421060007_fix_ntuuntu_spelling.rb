class FixNtuuntuSpelling < ActiveRecord::Migration[5.0]
  def up
    Household.where(subvillage: 'Ntutu').update_all(subvillage: 'Ntuuntu')
  end

  def down
    Household.where(subvillage: 'Ntuuntu').update_all(subvillage: 'Ntutu')
  end
end
