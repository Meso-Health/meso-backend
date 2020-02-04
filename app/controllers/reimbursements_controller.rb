class ReimbursementsController < ApplicationController
  before_action :require_reimbursement_permitted_user!
  before_action :parse_post_params!, only: [:create]
  before_action :parse_patch_params!, only: [:update]
  before_action :parse_reimbursable_metadata_params!, only: [:reimbursable_claims_metadata]

  def index
    provider_id = params[:provider_id]
    providers = provider_id.blank? ?
                    Provider.all :
                    [Provider.find(params[:provider_id])]

    reimbursements = Reimbursement.where(provider: providers).includes(:encounters)
    render json: ReimbursementRepresenter.for_collection.new(reimbursements).to_json
  end

  def create
    provider = Provider.find(params[:provider_id])
    reimbursement = provider.reimbursements.new(user: @current_user)

    representer = ReimbursementRepresenter.new(reimbursement)
    representer.from_hash(params)

    # We need to make sure that encounter_ids satisfies the following conditions:
    # - ids correspond to real encounters
    # - encounters are approved
    # - encounters do not have an associated reimbursement_id
    # - encounters have the same provider as the one included in the URL
    matching_encounters = Encounter.approved.where(id: @encounter_ids, reimbursement_id: nil, provider: provider)
    if @encounter_ids.size != matching_encounters.count
      error_message = "Reimbursements POST request did not specify a list of encounters that could be reimbursed for at this moment. Params: #{params.to_json}"
      Rollbar.error error_message
      render json: { errors: error_message }, status: 422
    else
      ActiveRecord::Base.transaction do
        reimbursement.encounters = matching_encounters
        reimbursement.save!
      end
      render json: representer.to_json, status: :created
    end
  end

  def update
    reimbursement = Reimbursement.find(params[:id])
    # If the reimbursement is not editable, this patch request should not be allowed.
    unless reimbursement.editable?
      error_message = "Tried to PATCH a reimbursement that is not editable. Reimbursement from DB: #{reimbursement.to_json}, params: #{params.to_json}"
      Rollbar.error error_message
      render json: { errors: error_message }, status: 405
      return
    end

    representer = ReimbursementRepresenter.new(reimbursement)
    representer.from_hash(params)

    if @is_date_adjustment
      # We need to make sure that encounter_ids satisfies the following conditions:
      # - ids correspond to real encounters
      # - encounters are approved
      # - encounters are either not reimbursed or are reimbursed under the specified reimbursement in the POST
      matching_encounters = Encounter.approved.where(id: @encounter_ids, reimbursement_id: [nil, reimbursement.id])
      if @encounter_ids.size != matching_encounters.count
        error_message = "Reimbursements PATCH request did not specify a list of encounters that could be reimbursed for at this moment. Params: #{params.to_json}"
        Rollbar.error error_message
        render json: { errors: error_message }, status: 422
        return
      else
        ActiveRecord::Base.transaction do
          reimbursement.encounters = matching_encounters
          reimbursement.save!
        end
      end
    end
    if @is_payment_completion
      reimbursement.completed_at = Time.zone.now
      reimbursement.save!
    end

    render json: representer.to_json
  end

  def stats
    provider_id = params[:provider_id]
    providers = provider_id.blank? ?
                    Provider.includes(:encounters, :reimbursements).all :
                    [Provider.includes(:encounters, :reimbursements).find(params[:provider_id])]
      json = []
      for provider in providers do
        last_reimbursement = provider.reimbursements.paid.order(:payment_date).last
        last_payment_date = last_reimbursement != nil ? last_reimbursement.payment_date : nil
        approved_claim_count = provider.encounters.preloaded.approved.not_reimbursed.count
        approved_claim_total = provider.encounters.preloaded.approved.not_reimbursed.map(&:reimbursal_amount).sum
        pending_claim_count = provider.encounters.preloaded.pending.not_reimbursed.count
        pending_claim_total = provider.encounters.preloaded.pending.not_reimbursed.map(&:reimbursal_amount).sum
        returned_claim_count = provider.encounters.preloaded.returned.not_reimbursed.count
        returned_claim_total = provider.encounters.preloaded.returned.not_reimbursed.map(&:reimbursal_amount).sum
        rejected_claim_count = provider.encounters.preloaded.rejected.not_reimbursed.count
        rejected_claim_total = provider.encounters.preloaded.rejected.not_reimbursed.map(&:reimbursal_amount).sum

        provider_json = {
          provider_id: provider.id,
          last_payment_date: last_payment_date,
          approved: {
              claims_count: approved_claim_count,
              total_price: approved_claim_total,
          },
          pending: {
              claims_count: pending_claim_count,
              total_price: pending_claim_total,
          },
          returned: {
              claims_count: returned_claim_count,
              total_price: returned_claim_total,
          },
          rejected: {
              claims_count: rejected_claim_count,
              total_price: rejected_claim_total,
          },
          total: {
              claims_count: approved_claim_count + pending_claim_count + returned_claim_count,
              total_price: approved_claim_total + pending_claim_total + returned_claim_total,
          },
        }
        json.push(provider_json)
      end

    render json: json
  end

  def claims
    reimbursement = Reimbursement.find(params[:reimbursement_id])

    render json: EncounterWithMemberRepresenter.for_collection.new(reimbursement.encounters).to_json(mrn_key: @current_user.mrn_key)
  end

  def reimbursable_claims_metadata
    encounters = @provider.encounters.preloaded.approved.where(reimbursement_id: [@reimbursement_id, nil]).order(:adjudicated_at).where('adjudicated_at::date <= ?', @end_date)

    start_date = encounters.first.adjudicated_at&.to_date
    total_price = encounters.map(&:reimbursal_amount).sum
    encounter_ids = encounters.map(&:id)

    render json: { total_price: total_price, start_date: start_date, end_date: @end_date, encounter_ids: encounter_ids }
  end

  private

  def parse_post_params!
    @encounter_ids = params[:encounter_ids]
    if @encounter_ids.blank?
      error_message = "Reimbursement POST request requires non-empty list of encounter_ids. Params: #{params.to_json}"
      Rollbar.error error_message
      render json: { errors: error_message }, status: 422
    end
  end

  def parse_patch_params!
    @encounter_ids = params[:encounter_ids]
    @is_date_adjustment = @encounter_ids.present?
    @is_payment_completion = params[:reimbursement][:payment_date] && params[:reimbursement][:payment_field]

    unless @is_date_adjustment ^ @is_payment_completion
      error_message = "Reimbursements PATCH request requires EITHER a non-empty list of encounter_ids OR a reimbursement with a payment_date and payment_field. Params: #{params.to_json}"
      Rollbar.error error_message
      render json: { errors: error_message }, status: 422
    end
  end

  def parse_reimbursable_metadata_params!
    if params[:provider_id] == nil
      ExceptionsApp.for(:bad_request).render(self)
    end
    @provider = Provider.includes(:encounters).find(params[:provider_id])
    @end_date = Date.parse(params[:end_date])
    @reimbursement_id = params[:reimbursement_id]
  rescue TypeError, ArgumentError
    ExceptionsApp.for(:bad_request).render(self)
  end
end
