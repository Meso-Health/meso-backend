class DiagnosesController < ApplicationController
  def index
    diagnoses = @current_user.provider&.diagnoses&.active
    if diagnoses.blank?
      diagnoses = Diagnosis.active
    end

    if stale?(diagnoses)
      render json: DiagnosisRepresenter.for_collection.new(diagnoses).to_json
    end
  end
end
