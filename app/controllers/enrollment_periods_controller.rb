class EnrollmentPeriodsController < ApplicationController
  def index
    user_administrative_division = @current_user.administrative_division
    enrollment_periods = if user_administrative_division
      # A user should have access to all enrollment periods whose administrative division contain the user's admin division,
      # as well as any enrollment periods whose administrative division is within the user's admin division.
      # In other words, all ancestors and descendants.
      EnrollmentPeriod.where(administrative_division: user_administrative_division.self_and_ancestors + user_administrative_division.self_and_descendants)
    else
      EnrollmentPeriod.all
    end

    render json: EnrollmentPeriodRepresenter.for_collection.new(enrollment_periods).to_json
  end
end
