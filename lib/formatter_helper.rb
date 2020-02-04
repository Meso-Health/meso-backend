# Module for us to keep our formatters that format data for user readability
include EthiopianDateHelper

module FormatterHelper
  # formats currency to a user readable way
  # '9870' --> '98.70'
  def format_currency(amount)
    '%.2f' % (amount / 100.00)
  end

  # formats UUIDs to a user readable way
  # '2c6de5e1-89d1-438e-aef5-f208f42737b1' --> '2C6DE5E1'
  def format_short_id(id)
    id.split('-').first.upcase
  end

  def format_time_now
    if ENV['ADMIN_PANEL_DATE_FORMAT'] == 'ethiopian'
      EthiopianDateHelper::from_gregorian_date_to_ethiopian_date_string(Time.zone.now)
    else
      Time.zone.now.to_s
    end
  end

  def format_date(datetime)
    if ENV['ADMIN_PANEL_DATE_FORMAT'] == 'ethiopian'
      datetime && EthiopianDateHelper::from_gregorian_date_to_ethiopian_date_string(datetime)
    else
      datetime && datetime.to_date.to_s
    end
  end
end
