class AutoIncrementAdministrativeDivisionId < ActiveRecord::Migration[5.0]
  def change
    AdministrativeDivision.connection.execute("ALTER SEQUENCE administrative_divisions_id_seq RESTART WITH #{(AdministrativeDivision.maximum(:id) || 0)+1}")
  end
end