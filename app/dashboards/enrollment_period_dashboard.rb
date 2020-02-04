require "administrate/base_dashboard"

class EnrollmentPeriodDashboard < BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    versions: Field::HasMany.with_options(class_name: "PaperTrail::Version"),
    provider: Field::BelongsTo,
    administrative_division: Field::BelongsTo,
    id: Field::Number,
    start_date: DateField,
    end_date: DateField,
    coverage_start_date: DateField,
    coverage_end_date: DateField, 
    created_at: DateField,
    updated_at: DateField,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :start_date,
    :end_date,
    :coverage_start_date,
    :coverage_end_date,
    :administrative_division,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :start_date,
    :end_date,
    :coverage_start_date,
    :coverage_end_date,
    :administrative_division,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :start_date,
    :end_date,
    :coverage_start_date,
    :coverage_end_date,
    :administrative_division
  ].freeze

  # Overwrite this method to customize how enrollment periods are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(enrollment_period)
  #   "EnrollmentPeriod ##{enrollment_period.id}"
  # end
end