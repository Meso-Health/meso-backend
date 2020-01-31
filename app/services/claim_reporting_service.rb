include FormatterHelper

class ClaimReportingService
  def initialize(claims, provider_designation, formatted_start_date, formatted_end_date)
    @claims = claims
    @provider_designation = provider_designation
    @start_date = formatted_start_date
    @end_date = formatted_end_date
  end

  def generate_csv
    CSV.generate do |csv|
      rows = [
        ['Provider', @provider_designation.humanize],
        ['Date Range', @start_date && @end_date ? "#{@start_date} - #{@end_date}" : nil],
        [nil],
        [
          'Claim ID',
          'Date of Service',
          'Date of Submission',
          'Beneficiary ID',
          'Name',
          'Address',
          'Sex',
          'Age',
          'MRN',
          'Diagnosis',
          'Visit Type',
          'Services',
          'Procedures',
          'Bed Day',
          'Labs',
          'Imaging',
          'Drug & Supplies',
          'Total',
          'Requested Reimbursal Amount'
        ]
      ]
      rows.each { |row| csv << row }

      @claims.each do |claim|
        last_encounter = claim.last_encounter
        member = last_encounter.member
        encounter_items_by_billable_type = last_encounter.encounter_items.group_by { |ei| ei.billable.type }

        csv << [
          FormatterHelper.format_short_id(claim.id),
          FormatterHelper.format_date(last_encounter.occurred_at),
          FormatterHelper.format_date(last_encounter.submitted_at),
          member.membership_number,
          member.full_name,
          member.household ? member.household.administrative_division.name : nil,
          member.gender,
          FormatterHelper.format_date(member.birthdate.to_date),
          member.medical_record_number_from_key(last_encounter.provider_id),
          last_encounter.diagnoses.pluck(:description).join(', '),
          last_encounter.visit_type,
          FormatterHelper.format_currency(encounter_items_by_billable_type['service']&.sum(&:price) || 0),
          FormatterHelper.format_currency(encounter_items_by_billable_type['procedure']&.sum(&:price) || 0),
          FormatterHelper.format_currency(encounter_items_by_billable_type['bed_day']&.sum(&:price) || 0),
          FormatterHelper.format_currency(encounter_items_by_billable_type['lab']&.sum(&:price) || 0),
          FormatterHelper.format_currency(encounter_items_by_billable_type['imaging']&.sum(&:price) || 0),
          FormatterHelper.format_currency(encounter_items_by_billable_type['drug']&.sum(&:price) || 0),
          FormatterHelper.format_currency(last_encounter.price),
          FormatterHelper.format_currency(last_encounter.reimbursal_amount)
        ]
      end

      csv
    end
  end
end
