require "administrate/base_dashboard"

class BillableDashboard < BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::String.with_options(searchable: false),
    type: Field::Select.with_options(collection: Billable::TYPES),
    name: Field::String,
    composition: Field::String,
    unit: Field::String,
    accounting_group: Field::Select.with_options(collection: Billable::ACCOUNTING_GROUP_NAMES),
    active: Field::Boolean,
    reviewed: Field::Boolean,
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
    :name,
    :type,
    :composition,
    :unit,
    :accounting_group,
    :active,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :name,
    :type,
    :composition,
    :unit,
    :accounting_group,
    :active,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :name,
    :type,
    :composition,
    :unit,
    :accounting_group,
    :active,
  ].freeze

  # Overwrite this method to customize how billables are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(billable)
    "Billable ##{billable.id} (#{billable.name} #{billable.unit} #{billable.composition})" 
  end
end
