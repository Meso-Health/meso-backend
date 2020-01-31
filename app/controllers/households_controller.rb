class HouseholdsController < ApplicationController
  def create
    household_record = Household.new

    representer = HouseholdRepresenter.new(household_record)
    representer.from_hash(params)

    household_record.save_with_id_collision!

    render json: representer.to_json, status: :created
  end

  def search
    members = Member.filter_with_params(params.merge(mrn_key: @current_user.mrn_key)).includes(:household)
    if members.present?
      household_ids = members.distinct.pluck(:household_id)
      households = Household.where(id: household_ids).includes(:members)
      render json: HouseholdRepresenter.for_collection.new(households).to_json(
        mrn_key: @current_user.mrn_key
      )
    else
      render json: []
    end
  end
end
