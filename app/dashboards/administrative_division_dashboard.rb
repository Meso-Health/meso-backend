require "administrate/base_dashboard"

 class AdministrativeDivisionDashboard < BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    parent: Field::BelongsTo.with_options(class_name: "AdministrativeDivision"),
    id: Field::Number,
    name: Field::String,
    level: Field::Select.with_options(
      # TODO: make this configurable
      collection: %w[region parish village subvillage],
    ),
    code: Field::String,
    parent_id: Field::Number,
    created_at: DateField,
    updated_at: DateField,
  }.freeze

   # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :name,
    :level,
    :code,
  ].freeze

   # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :name,
    :level,
    :code,
    :created_at,
    :updated_at,
    :parent,
  ].freeze

   # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :name,
    :level,
    :code,
    :parent,
  ].freeze

   # Overwrite this method to customize how administrative divisions are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(administrative_division)
    "##{administrative_division.id} #{administrative_division.name} (#{administrative_division.level})"
  end
end
