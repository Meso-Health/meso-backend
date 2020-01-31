class IdentificationEventsController < ApplicationController
  def index
    provider = Provider.find(params[:provider_id])
    id_events = provider.identification_events.order(:occurred_at).reverse_order
    if stale?(id_events)
      render json: IdentificationEventRepresenter.for_collection.new(id_events).to_json(mrn_key: @current_user.mrn_key)
    end
  end

  def open
    provider = Provider.find(params[:provider_id])
    id_events = provider.identification_events.is_open

    if stale?(id_events)
      id_events = id_events.includes(member: [:household, :photo_attachment])
        .includes(encounter: [
          { encounter_items: :lab_result },
          :billables,
          :referrals,
          :resubmitted_encounter,
          :price_schedules,
          :diagnoses,
          :adjudicator,
          :user,
          :reimbursement
        ])
        .order(:occurred_at)
      render json: IdentificationEventWithEncounterAndMemberRepresenter
        .for_collection
        .new(id_events)
        .to_json(mrn_key: @current_user.mrn_key)
    end
  end

  def create
    provider = Provider.find(params[:provider_id])
    id_event = provider.identification_events.new(user: @current_user)

    representer = IdentificationEventRepresenter.new(id_event)
    representer.from_hash(params)
    id_event.save_with_id_collision!

    render json: representer.to_json, status: :created
  end

  def update
    id_event = IdentificationEvent.find(params[:id])

    representer = IdentificationEventRepresenter.new(id_event)
    representer.from_hash(params)
    id_event.save!

    render json: representer.to_json
  end
end
