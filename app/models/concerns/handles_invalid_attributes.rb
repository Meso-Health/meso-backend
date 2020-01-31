module HandlesInvalidAttributes
  extend ActiveSupport::Concern

  def save!
    self.invalid_attributes = reset_invalid_attributes!
    super
  end

  private

  def reset_invalid_attributes!
    prev_invalid_attributes = self.invalid_attributes.reject do |error_key, _|
      model, field_name = parse_model_and_field_from_key(error_key)
      model.send("#{field_name}_changed?")
    end

    unless valid?
      errors.keys.each do |error_key|
        # if the validation error corresponds to an association, the error key will include the
        # relation name (e.g. member.card_id) and restore_attribute must be called on the model
        # that contains the field, so this sets the model variable to the associated model
        # so that we can restore the invalid attribute on the offending model
        model, field_name = parse_model_and_field_from_key(error_key)
        model.send(:restore_attribute!, field_name)
      end
    end

    prev_invalid_attributes.merge(errors.to_h.except(:base))
  end
end

def parse_model_and_field_from_key(error_key)
  model = self
  key_parts = error_key.to_s.split('.')
  while key_parts.length > 1 do
    relation_name = key_parts.shift
    model = model.send(relation_name)
  end
  field_name = key_parts.last
  return model, field_name
end
