class AutoIncrementProviderId < ActiveRecord::Migration[5.0]
  def change
    AdministrativeDivision.connection.execute("ALTER SEQUENCE providers_id_seq RESTART WITH #{(Provider.maximum(:id) || 0)+1}")
  end
end
