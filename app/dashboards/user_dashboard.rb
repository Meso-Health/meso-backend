require "administrate/base_dashboard"

class UserDashboard < BaseDashboard
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
    authentication_tokens: Field::HasMany,
    reimbursements: Field::HasMany,
    id: Field::Number,
    name: Field::String,
    role: Field::Select.with_options(collection: User::ROLES),
    created_at: DateField,
    updated_at: DateField,
    username: Field::String,
    password: Field::String.with_options(searchable: false),
    email: Field::String,
    deleted_at: DateField,
    adjudication_limit: Field::Number,
  }.freeze

   # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :name,
    :username,
    :role,
    :provider,
    :administrative_division,
    :deleted_at,
  ].freeze

   # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :provider,
    :administrative_division,
    :id,
    :name,
    :username,
    :role,
    :created_at,
    :updated_at,
    :username,
    :deleted_at,
    :adjudication_limit,
  ].freeze

   # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :name,
    :role,
    :username,
    :password,
    :administrative_division,
    :provider,
    :adjudication_limit,
  ].freeze

   # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(user)
    "User ##{user.id} (#{user.username})"
  end
end
