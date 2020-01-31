class AdministrativeDivisionsController < ApplicationController
  def index
    @within_jurisdiction = ActiveModel::Type::Boolean.new.cast(params[:within_jurisdiction])
    divisions = @within_jurisdiction ? @current_user.administrative_division&.self_and_descendants : AdministrativeDivision.all

    if stale?(divisions)
      render json: AdministrativeDivisionRepresenter.for_collection.new(divisions).to_json
    end
  end
end
