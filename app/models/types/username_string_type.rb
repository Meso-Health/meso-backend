class UsernameStringType < ActiveRecord::Type::String
  def serialize(value)
    cast_value(super(value))
  end

  private
  def cast_value(value)
    return nil if value.nil?
    value.strip.downcase
  end
end
