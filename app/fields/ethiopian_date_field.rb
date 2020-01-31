require "administrate/field/base"
include EthiopianDateHelper

class EthiopianDateField < Administrate::Field::Base
  def to_s
    data && EthiopianDateHelper::from_gregorian_date_to_ethiopian_date_string(data.to_date)    
  end
end