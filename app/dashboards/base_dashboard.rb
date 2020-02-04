class BaseDashboard < Administrate::BaseDashboard
  # The which date we use is dependent on whether the dates should be Ethiopian. 
  DateField = if ENV['ADMIN_PANEL_DATE_FORMAT'] == 'ethiopian'
    EthiopianDateField
  else
    Field::DateTime.with_options(format: "%Y-%m-%d")
  end
end