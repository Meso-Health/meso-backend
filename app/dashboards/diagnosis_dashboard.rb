require "administrate/base_dashboard"

 class DiagnosisDashboard < BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    diagnoses_groups: Field::HasMany.with_options(exportable: false),
    id: Field::Number,
    description: Field::String,
    icd_10_codes: Field::String,
    created_at: DateField,
    updated_at: DateField,
    search_aliases: Field::String,
    active: Field:: Boolean,
  }.freeze

   # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :description,
    :active,
  ].freeze

   # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :diagnoses_groups,
    :id,
    :description,
    :active,
    :created_at,
    :updated_at,
  ].freeze

   # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :diagnoses_groups,
    :active,
    :description,
  ].freeze

   # Overwrite this method to customize how diagnoses are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(diagnosis)
    "Diagnosis: #{diagnosis.description}"
  end
end