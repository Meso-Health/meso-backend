require "administrate/base_dashboard"

 class CardBatchDashboard < BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    cards: Field::HasMany,
    id: Field::Number,
    prefix: Field::String,
    reason: Field::Text,
    created_at: DateField,
    updated_at: DateField,
    count: Field::Number,
  }.freeze

   # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :reason,
    :prefix,
    :count,
  ].freeze

   # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :prefix,
    :reason,
    :created_at,
    :updated_at,
    :count,
  ].freeze

   # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :prefix,
    :reason,
    :count,
  ].freeze

   # Overwrite this method to customize how card batches are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(card_batch)
  #   "CardBatch ##{card_batch.id}"
  # end
end