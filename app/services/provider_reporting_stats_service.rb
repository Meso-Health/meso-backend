include FormatterHelper

class ProviderReportingStatsService
  CARD = "card_and_consultation"
  SURGERY = "surgery"
  LAB = "lab"
  DRUGS = "drug_and_supply"
  BED_DAY = "bed_day_and_food"
  CAPITATION = "capitation"
  IMAGING = "imaging"
  OTHER = "other_services"
  ACCOUNTING_GROUPS = [CARD, SURGERY, LAB, DRUGS, BED_DAY, CAPITATION, IMAGING, OTHER]

  def initialize(provider_id, start_date, end_date)
    @provider = Provider.find(provider_id)
    @start_date = start_date
    @end_date = end_date
    provider_encounters = @provider.encounters
                              .includes(encounter_items: [:lab_result, :price_schedule])
                              .includes(:identification_event)

    # Whether a claim is within the date ranger is based on the initial_submission date.
    encounters = provider_encounters.initial_submissions
    encounters = encounters.where('encounters.submitted_at >= ?', @start_date) if @start_date
    encounters = encounters.where('encounters.submitted_at <= ?', @end_date) if @end_date
    claim_ids = encounters.map(&:claim_id)

    # Of these claims, the bin they belong to is based on the latest_submission's adjuducation_state.
    @encounters = provider_encounters.latest.where(claim_id: claim_ids)
    get_reimbursement_accounting_totals
  end

  def stats
    approved_claim_count = @encounters.approved.not_reimbursed.count
    approved_claim_total = @encounters.approved.not_reimbursed.map(&:reimbursal_amount).sum
    pending_claim_count = @encounters.pending.not_reimbursed.count
    pending_claim_total = @encounters.pending.not_reimbursed.map(&:reimbursal_amount).sum
    returned_claim_count = @encounters.returned.not_reimbursed.count
    returned_claim_total = @encounters.returned.not_reimbursed.map(&:reimbursal_amount).sum
    rejected_claim_count = @encounters.rejected.not_reimbursed.count
    rejected_claim_total = @encounters.rejected.not_reimbursed.map(&:reimbursal_amount).sum
    resubmitted_count = @encounters.resubmitted.count

    {
      approved: {
          claims_count: approved_claim_count,
          total_price: approved_claim_total,
      },
      rejected: {
        claims_count: rejected_claim_count,
        total_price: rejected_claim_total,
      },
      returned: {
        claims_count: returned_claim_count,
        total_price: returned_claim_total,
      },
      pending: {
        claims_count: pending_claim_count,
        total_price: pending_claim_total,
      },
      resubmitted_count: resubmitted_count,
      total: {
          claims_count: approved_claim_count + pending_claim_count + returned_claim_count + rejected_claim_count,
          price: approved_claim_total + pending_claim_total + returned_claim_total + rejected_claim_total,
      },
    }
  end

  private

  def get_reimbursement_accounting_totals
    totals = @encounters.map do |encounter|
      encounter.get_total_by_accounting_group(ACCOUNTING_GROUPS)
    end

    @card_and_consultation_total = get_values(totals, CARD).sum
    @lab_total = get_values(totals, LAB).sum
    @imaging_total = get_values(totals, IMAGING).sum
    @surgery_total = get_values(totals, SURGERY).sum
    @drug_and_supply_total = get_values(totals, DRUGS).sum
    @bed_day_and_food_total = get_values(totals, BED_DAY).sum
    @capitation_total = get_values(totals, CAPITATION).sum
    @other_services_total = get_values(totals, OTHER).sum
    @totals_total = [
        @card_and_consultation_total,
        @lab_total,
        @imaging_total,
        @surgery_total,
        @drug_and_supply_total,
        @bed_day_and_food_total,
        @capitation_total,
        @other_services_total
    ].sum
  end

  def get_values(array, key)
    array.map{ |x| x[key] }
  end
end
