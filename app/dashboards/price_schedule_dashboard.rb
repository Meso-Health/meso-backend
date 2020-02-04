require "administrate/base_dashboard"

class PriceScheduleDashboard < BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    provider: Field::BelongsTo,
    billable: Field::BelongsTo,
    previous_price_schedule: Field::BelongsTo.with_options(class_name: "PriceSchedule"),
    id: Field::String.with_options(searchable: false),
    issued_at: DateField,
    price: Field::Number,
    previous_price_schedule_id: Field::String.with_options(searchable: false),
    created_at: DateField,
    updated_at: DateField,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :provider,
    :billable,
    :price,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :provider,
    :previous_price_schedule,
    :id,
    :billable,
    :issued_at,
    :price,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :provider,
    :billable,
    :price,
  ].freeze

  # Overwrite this method to customize how price schedules are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(price_schedule)
  #   "PriceSchedule ##{price_schedule.id}"
  # end
end
