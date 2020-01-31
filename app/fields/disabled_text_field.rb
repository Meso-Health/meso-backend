require "administrate/field/base"

class DisabledTextField < Administrate::Field::String
  def to_s
    data
  end
end
