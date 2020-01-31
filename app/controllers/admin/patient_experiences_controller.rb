module Admin
  class PatientExperiencesController < Admin::ApplicationController
    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   foo = Foo.find(params[:id])
    #   foo.update(params[:foo])
    #   send_foo_updated_email
    # end

    # Override this method to specify custom lookup behavior.
    # This will be used to set the resource for the `show`, `edit`, and `update`
    # actions.
    #
    # def find_resource(param)
    #   Foo.find_by!(slug: param)
    # end

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    #
    # def scoped_resource
    #  if current_user.super_admin?
    #    resource_class
    #  else
    #    resource_class.with_less_stuff
    #  end
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
    def create
      resource = resource_class.new(resource_params.except(:count))
      authorize_resource(resource)

      ActiveRecord::Base.transaction do
        if resource.save
          redirect_to(
              [namespace, resource],
              notice: translate_with_resource("create.success"),
              )
          return
        end
      end
      redirect_to(
          new_admin_patient_experience_path(encounter_id: resource_params[:encounter_id],),
          notice: "Patient experience not saved. Check that inputs are valid.",
      )
    end

    def new
      encounter = params[:encounter_id].blank? ? nil : Encounter.find(params[:encounter_id])
      if encounter.blank?
        redirect_to(
            [namespace, "patient_experiences"],
            notice: "Encounter_id required for new patient experience",
            )
        return
      end
      member = Member.find(encounter.member_id)
      resource = PatientExperience.new(encounter_id: encounter.id)
      authorize_resource(resource)
      render locals: {
          member: {
              name: member.full_name,
              phone: member.phone_number,
          },
          page: Administrate::Page::Form.new(dashboard, resource),
      }
    rescue ActiveRecord::RecordNotFound
      redirect_to(
          [namespace, resource],
          notice: "Valid Encounter_id required for new patient experience",
      )
    end
  end
end
