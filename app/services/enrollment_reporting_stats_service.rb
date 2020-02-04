include FormatterHelper

class EnrollmentReportingStatsService
  def initialize(filters = {})
    @filters = HashWithIndifferentAccess.new(filters)
  end

  def generate_stats
    household_enrollment_records = filtered_enrollment_records_query
    distinct_households = household_enrollment_records.select('DISTINCT household_enrollment_records.household_id').count
    distinct_members = household_enrollment_records.left_joins(household: :members).select('DISTINCT members.id').count
    payment_totals = household_enrollment_records.joins(:membership_payments).pluck(
      'SUM(annual_contribution_fee)',
      'SUM(qualifying_beneficiaries_fee)',
      'SUM(registration_fee)',
      'SUM(penalty_fee)',
      'SUM(other_fee)',
      'SUM(card_replacement_fee)',
    ).first

    {
      members: distinct_households,
      beneficiaries: distinct_members - distinct_households,
      membership_payment: {
        annual_contribution_fee: payment_totals[0],
        qualifying_beneficiaries_fee: payment_totals[1],
        registration_fee: payment_totals[2],
        penalty_fee: payment_totals[3],
        other_fee: payment_totals[4],
        card_replacement_fee: payment_totals[5],
      }
    }
  end

  def filtered_enrollment_records_query
    query = HouseholdEnrollmentRecord

    if administrative_divison_id = @filters[:administrative_division_id]
      # TODO: make sure the current user has permission to access the requested scope
      administrative_division = AdministrativeDivision.find(administrative_divison_id)
      administrative_division_ids_to_load = AdministrativeDivision.self_and_descendants_ids(administrative_division)
      query = query.where(administrative_division_id: administrative_division_ids_to_load)
    end

    if start_date = @filters[:start_date]
      query = query.where('household_enrollment_records.enrolled_at >= ?', start_date)
    end

    if end_date = @filters[:end_date]
      query = query.where('household_enrollment_records.enrolled_at <= ?', end_date)
    end

    # Intentionally chose to use the string syntax to make it more future-proof in case another
    # 'paying' field is introduced on a joined model in the future
    if paying = @filters[:paying]
      query = query.where('household_enrollment_records.paying = ?', paying)
    end

    if renewal = @filters[:renewal]
      query = query.where('household_enrollment_records.renewal = ?', renewal)
    end

    if gender = @filters[:gender]
      # the gender filter applies to the head of household, not each individual
      query = query.joins(%Q(
        INNER JOIN members filtered ON
          household_enrollment_records.household_id = filtered.household_id AND
          filtered.relationship_to_head = 'SELF' AND
          filtered.gender = '#{gender}'
      ))
    end

    query
  end
end
