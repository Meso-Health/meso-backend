class EncountersController < ApplicationController
  def index
    encounters = Encounter.all

    if stale?(encounters)
      encounters = encounters.preloaded
        .order(:occurred_at)
        .reverse_order
      render json: EncounterWithMemberRepresenter
        .for_collection
        .new(encounters)
        .to_json(mrn_key: @current_user.mrn_key)
    end
  end

  def returned
    @provider_id = params[:provider_id]
    encounters = Provider.find(@provider_id).encounters.returned

    if stale?(encounters)
      encounters = encounters.preloaded
        .order(:occurred_at)
        .reverse_order
      render json: EncounterWithMemberRepresenter
        .for_collection
        .new(encounters)
        .to_json(mrn_key: @current_user.mrn_key)
    end
  end

  def create
    provider = Provider.find(params[:provider_id])
    encounter = provider.encounters.new(user: @current_user)

    representer = EncounterRepresenter.new(encounter)
    representer.from_hash(params)

    # TODO: remove after android clients have updated to setting submission_state themselves
    if encounter.submission_state.blank?
      if encounter.prepared_at.nil? && encounter.submitted_at.nil? # hospital id app
        encounter.submission_state = 'started'
      elsif encounter.prepared_at.present? && encounter.submitted_at.present? # clinic app
        encounter.submission_state = 'submitted'
      else
        error_message = "Android client only expected to sync up partial or fully submitted encounters. Params: #{params}, Encounter: #{encounter.to_json}"
        Rollbar.error error_message
        render json: { errors: error_message }, status: 405
        return
      end
    end

    encounter.save_with_id_collision!
    if ActiveModel::Type::Boolean.new.cast(ENV['ENABLE_ENCOUNTER_RECONCILIATION'])
      encounter = run_reconciliation_and_reload(encounter)
    end
    encounter = run_pool_filtering_and_reload(encounter)
    representer = EncounterRepresenter.new(encounter)

    render json: representer.to_json, status: :created
  end

  def update
    encounter = Encounter.find(params[:id])

    is_adjudication = params[:adjudication_state].present? && encounter.adjudication_state != params[:adjudication_state]

    if is_adjudication && @current_user.adjudication_limit.present? && encounter.reimbursal_amount > @current_user.adjudication_limit
      error_message = "Encounter is outside the adjudication limits. Params: #{params}, Encounter: #{encounter.to_json}"
      Rollbar.error error_message
      render json: { errors: error_message }, status: 405
      return
    end


    if !encounter.reimbursed?
      representer = EncounterRepresenter.new(encounter)

      Encounter.transaction do
        representer.from_hash(params)
        encounter.save!

        if ActiveModel::Type::Boolean.new.cast(ENV['ENABLE_ENCOUNTER_RECONCILIATION'])
          encounter = run_reconciliation_and_reload(encounter)
        end
        encounter = run_pool_filtering_and_reload(encounter)
        if encounter.submitted?
          if encounter.inbound_referral_date != nil
            encounter = run_referral_match_from_encounter_service_and_reload(encounter)
          end
          if encounter.referrals != nil && encounter.referrals.length > 0
            run_referral_match_from_referral_service(encounter.referrals)
          end
        end

        representer = EncounterRepresenter.new(encounter)

        render json: representer.to_json
      end
    else
      error_message = "Encounter is not editable because it already has a reimbursement. Params: #{params}, Encounter: #{encounter.to_json}"
      Rollbar.error error_message
      render json: { errors: error_message }, status: 405
    end
  end

  def run_reconciliation_and_reload(encounter)
    EncounterReconciliationService.new.reconcile!(encounter)
    encounter.reload
  end

  def run_referral_match_from_referral_service(referrals)
    for referral in referrals
      ReferralMatchingService.new.match_from_referral!(referral)
    end
  end

  def run_referral_match_from_encounter_service_and_reload(encounter)
    ReferralMatchingService.new.match_from_inbound_referral_date!(encounter)
    encounter.reload
  end

  def run_pool_filtering_and_reload(encounter)
    EncounterPoolFilterService.new.filter_by_pool!(encounter)
    encounter.reload
  end
end
