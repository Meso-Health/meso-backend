require "administrate/base_dashboard"

 class ProviderDashboard < BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    # TODO: Figure out a way to restrict to correct administrative division level
    administrative_division: Field::BelongsTo,
    diagnoses_group: Field::BelongsTo,
    users: Field::HasMany,
    created_at: DateField,
    updated_at: DateField,
    security_pin: Field::String,
    provider_type: Field::Select.with_options(
      collection: %w[health_center primary_hospital general_hospital tertiary_hospital]
    ),
    contracted: Field::Boolean,
  }.freeze

   # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :name,
    :administrative_division,
  ].freeze

   # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :name,
    :diagnoses_group,
    :administrative_division,
    :security_pin,
    :users,
    :created_at,
    :updated_at,
    :provider_type,
    :contracted,
  ].freeze

   # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :administrative_division,
    :diagnoses_group,
    :name,
    :security_pin,
    :provider_type,
    :contracted,
  ].freeze

   # Overwrite this method to customize how providers are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(provider)
    "Provider ##{provider.id} (#{provider.name})"
  end
end
