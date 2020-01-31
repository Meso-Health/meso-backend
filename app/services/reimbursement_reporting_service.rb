include FormatterHelper

class ReimbursementReportingService
  CARD = "card_and_consultation"
  SURGERY = "surgery"
  LAB = "lab"
  DRUGS = "drug_and_supply"
  BED_DAY = "bed_day_and_food"
  CAPITATION = "capitation"
  IMAGING = "imaging"
  OTHER = "other_services"
  ACCOUNTING_GROUPS = [CARD, SURGERY, LAB, DRUGS, BED_DAY, CAPITATION, IMAGING, OTHER]

  def initialize(reimbursement_id)
    @reimbursement = Reimbursement.find(reimbursement_id)
    @claims = @reimbursement.encounters.order('adjudicated_at')
      .includes( member: { household: :administrative_division } )
      .includes(:encounter_items)
      .includes(:billables)
      .includes(:price_schedules)

    get_reimbursement_accounting_totals
  end

  def generate_csv
    provider = @reimbursement.provider
    administrative_division = provider.administrative_division

    start_end_date = "#{FormatterHelper::format_date(reimbursement_start_date)} - #{FormatterHelper::format_date(reimbursement_end_date)}"

    CSV.generate do |csv|
      rows = [
        [ 'Facility name', provider.name, administrative_division.name, start_end_date ],
        [ 'Total number of claims', @claims.count ],
        [ 'Total amount', FormatterHelper::format_currency(@reimbursement.total) ],
        [ ' Payment summary' ],
        [
            nil,
            'Card and consultation Fee',
            'Laboratory Fee',
            'Imaging Fee',
            'Procedures/Services Fee',
            'Drug and Supply Fee',
            'Bed Fee',
            'Other services',
            'Total',
        ],
        [
          nil,
          FormatterHelper::format_currency(@card_and_consultation_total),
          FormatterHelper::format_currency(@lab_total),
          FormatterHelper::format_currency(@imaging_total),
          FormatterHelper::format_currency(@surgery_total),
          FormatterHelper::format_currency(@drug_and_supply_total),
          FormatterHelper::format_currency(@bed_day_and_food_total),
          FormatterHelper::format_currency(@other_services_total),
          FormatterHelper::format_currency(@totals_total),
        ],
        [ nil ],
        [ 'Claims list' ]
      ]
      rows.each { |row| csv << row }

      csv << [
        nil,
        'S/N',
        'Claim ID',
        'Beneficiary ID',
        'Sex',
        'Age',
        'Date of Service',
        'MRN No.',
        'Address',
        'Visit Type',
        'Card and Consultation',
        'Laboratory',
        'Imaging',
        'Procedures/Services',
        'Drug and Supply',
        'Bed and Food',
        'Others',
        'Total',
        'Date of Submission'
      ]

      @claims.each_with_index do |claim, i|
        member = claim.member
        claim_accounting_totals = claim.get_total_by_accounting_group(ACCOUNTING_GROUPS)

        csv << [
            nil,
            i+1,
            FormatterHelper::format_short_id(claim.id),
            member.membership_number,
            member.gender,
            FormatterHelper::format_date(member.birthdate),
            FormatterHelper::format_date(claim.occurred_at),
            member.medical_record_number_from_key(claim.provider_id),
            member.household ? member.household.administrative_division.name : nil,
            claim.visit_type,
            FormatterHelper::format_currency(claim_accounting_totals[CARD]),
            FormatterHelper::format_currency(claim_accounting_totals[LAB]),
            FormatterHelper::format_currency(claim_accounting_totals[IMAGING]),
            FormatterHelper::format_currency(claim_accounting_totals[SURGERY]),
            FormatterHelper::format_currency(claim_accounting_totals[DRUGS]),
            FormatterHelper::format_currency(claim_accounting_totals[BED_DAY]),
            FormatterHelper::format_currency(claim_accounting_totals[OTHER]),
            FormatterHelper::format_currency(claim.reimbursal_amount),
            FormatterHelper::format_date(claim.submitted_at),
        ]
      end

      csv
    end
  end

  private
  def reimbursement_start_date
    @claims.first.adjudicated_at
  end

  def reimbursement_end_date
    @claims.last.adjudicated_at
  end

  def get_reimbursement_accounting_totals
    totals = @claims.map do |claim|
      claim.get_total_by_accounting_group(ACCOUNTING_GROUPS)
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
