class Encounter < ApplicationRecord
  ADJUDICATION_STATES = %w[pending approved returned revised rejected external]
  SUBMISSION_STATES = %w[started prepared submitted needs_revision]
  include HasAttachments

  belongs_to :provider
  belongs_to :user
  belongs_to :adjudicator, class_name: 'User', optional: true
  belongs_to :auditor, class_name: 'User', optional: true
  belongs_to :member
  belongs_to :identification_event, optional: true
  belongs_to :revised_encounter, class_name: 'Encounter', optional: true, inverse_of: :resubmitted_encounter
  belongs_to :reimbursement, optional: true
  belongs_to :referral, optional: true
  has_many :referrals, dependent: :destroy, autosave: true
  has_one :resubmitted_encounter, class_name: 'Encounter', foreign_key: 'revised_encounter_id', inverse_of: :revised_encounter
  has_many :encounter_items, dependent: :destroy, autosave: true
  has_many :price_schedules, through: :encounter_items
  has_many :billables, through: :encounter_items
  has_and_belongs_to_many :diagnoses

  has_attachments :forms

  validates :occurred_at, presence: true
  validates :copayment_amount, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :has_fever, inclusion: { in: [true, false] }, allow_nil: true
  validates_associated :encounter_items

  validates :submission_state, inclusion: { in: SUBMISSION_STATES }
  validates :prepared_at, absence: true, if: :started?
  validates :prepared_at, presence: true, unless: :started?
  validates :submitted_at, absence: true, unless: :submitted?
  validates :submitted_at, presence: true, if: :submitted?
  validates :adjudication_state, absence: true, unless: :submitted?

  validates :adjudication_state, inclusion: { in: ADJUDICATION_STATES }, allow_nil: true
  validates :adjudication_state, absence: true, unless: :submitted?
  validates :adjudicator, presence: true, unless: ->(encounter) { encounter.pending? || encounter.external? || encounter.adjudication_state.nil? }
  validates :adjudicator, absence: true, if: ->(encounter) { encounter.pending? || encounter.external? || encounter.adjudication_state.nil? }
  validates :adjudicated_at, presence: true, unless: ->(encounter) { encounter.pending? || encounter.external? || encounter.adjudication_state.nil? }
  validates :adjudicated_at, absence: true, if: ->(encounter) { encounter.pending? || encounter.external? || encounter.adjudication_state.nil? }
  validates :custom_reimbursal_amount, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true

  validates :audited_at, presence: true, if: :auditor_id?

  scope :started, -> { where(submission_state: 'started') }
  scope :prepared, -> { where(submission_state: 'prepared') }
  scope :submitted, -> { where(submission_state: 'submitted') }
  scope :needs_revision, -> { where(submission_state: 'needs_revision') }

  scope :pending, -> { where(adjudication_state: 'pending') }
  scope :approved, -> { where(adjudication_state: 'approved') }
  scope :returned, -> { where(adjudication_state: 'returned') }
  scope :rejected, -> { where(adjudication_state: 'rejected') }
  scope :external, -> { where(adjudication_state: 'external') }
  scope :not_reimbursed, -> { where(reimbursement_id: nil) }
  scope :reimbursed, -> { where.not(reimbursement_id: nil) }
  scope :preloaded, lambda {
    preload_forms
      .includes(:provider)
      .includes(encounter_items: [:lab_result, :billable, price_schedule: :previous_price_schedule])
      .includes(member: [:household, :photo_attachment])
      .includes(:resubmitted_encounter)
      .includes(referral: [:receiving_encounter, encounter: :provider])
      .includes(:referrals)
      .includes(:identification_event, :diagnoses)
      .includes(:adjudicator)
      .includes(:user)
      .includes(:reimbursement)
  }

  scope :non_duplicates, -> { includes(:identification_event).where(identification_events: { dismissed: false }) }
  scope :resubmitted, -> { where.not(revised_encounter_id: nil) }
  scope :not_resubmitted, -> { where(revised_encounter_id: nil) }
  scope :paid, -> { where.not(reimbursement_id: nil) }
  scope :unpaid, -> { where(reimbursement_id: nil) }
  scope :audited, -> { where.not(audited_at: nil) }
  scope :not_audited, -> { where(audited_at: nil) }

  scope :with_unconfirmed_member, -> { joins(:member).where(members: { household_id: nil }) }
  scope :with_inactive_member_at_time_of_service, lambda { # TODO: consider replacing this complex and fragile SQL with an member_inactive field on encounter
    left_outer_joins(member: [household: [household_enrollment_records: :enrollment_period]])
      .where(where_inactive_member_at_time_of_service_sql)
      .distinct
  }
  scope :with_unlinked_inbound_referral, -> { where.not(inbound_referral_date: nil).where(referral_id: nil) }
  scope :all_flagged, lambda {
    left_outer_joins(member: [household: [household_enrollment_records: :enrollment_period]])
      .load_costs
      .where("members.household_id IS NULL
        OR #{where_inactive_member_at_time_of_service_sql}
        OR encounters.inbound_referral_date IS NOT NULL AND encounters.referral_id IS NULL
        OR encounters.custom_reimbursal_amount > (encounter_costs.price + 1) / 2")
      .distinct
  }
  scope :not_flagged, -> { where.not(id: all_flagged.pluck(:id)) } # TODO: this has a limit (https://stackoverflow.com/questions/1009706/postgresql-max-number-of-parameters-in-in-clause)

  # The following scopes are used for claim pagination.
  # Ties in sorting by other fields are broken using the claim_id field.
  # In order for claim_id to be a unique field for a list of encounters, `.latest` is used to select only the last encounter per claim.
  scope :latest, lambda {
    # ignore duplicate encounters since they're not considered to be "claims"
    non_duplicates
      .includes(:resubmitted_encounter).where(resubmitted_encounters_encounters: { revised_encounter_id: nil })
  }
  scope :initial_submissions, lambda {
    non_duplicates
      .where(revised_encounter_id: nil)
  }
  scope :load_costs, lambda {
    joins("JOIN (#{Encounter.price_and_reimbursal_amount_sql}) encounter_costs ON encounter_costs.encounter_id = encounters.id")
  }
  scope :sort_by_field, lambda { |sort_field, sort_direction|
    # note: sorting by reimbursal_amount will not work unless `load_costs` is called first
    sort_field_sql = sort_field == 'reimbursal_amount' ? 'encounter_costs.reimbursal_amount' : "encounters.#{sort_field}"
    order("#{sort_field_sql} #{sort_direction}, encounters.claim_id #{sort_direction}")
  }
  # We only need to match fields that _start_ with the query (vs. matching on any position).
  # This also allows us to leverage the additional speed-up from indices on the fields.
  scope :search_by_field, lambda { |search_field, search_query|
    if search_field == 'claim_id'
      where('encounters.claim_id like ?', "#{search_query}%")
    elsif search_field == 'membership_number'
      joins(:member).where('members.membership_number like ?', "#{search_query}%")
    end
  }
  scope :starting_after, lambda { |claim_encounter, sort_field, sort_direction|
    # note: sorting by reimbursal_amount will not work unless `load_costs` is called first
    sort_field_sql = sort_field == 'reimbursal_amount' ? 'encounter_costs.reimbursal_amount' : "encounters.#{sort_field}"
    where(
      "(#{sort_field_sql}, encounters.claim_id) #{sort_direction == 'desc' ? '<' : '>'} (?, ?)",
      claim_encounter.send(sort_field),
      claim_encounter.claim_id
    )
  }
  scope :ending_before, lambda { |claim_encounter, sort_field, sort_direction|
    # note: sorting by reimbursal_amount will not work unless `load_costs` is called first
    sort_field_sql = sort_field == 'reimbursal_amount' ? 'encounter_costs.reimbursal_amount' : "encounters.#{sort_field}"
    where(
      "(#{sort_field_sql}, encounters.claim_id) #{sort_direction == 'desc' ? '>' : '<'} (?, ?)",
      claim_encounter.send(sort_field),
      claim_encounter.claim_id
    )
  }

  # note: too complicated to tell whether a member was paying or indigent for a given date so just use current paying/indigent status
  scope :for_paying_member, -> { includes(member: [household: :household_enrollment_records]).where(members: { household: { household_enrollment_records: { paying: true } } }) }
  scope :for_indigent_member, -> { includes(member: [household: :household_enrollment_records]).where(members: { household: { household_enrollment_records: { paying: false } } }) }

  before_save :set_submitted_encounter_as_pending
  after_create :set_revised_encounter_as_revised

  def self.to_claims(encounters)
    encounters.group_by(&:claim_id).map do |claim_id, claim_encounters|
      Claim.new(id: claim_id, encounters: claim_encounters)
    end
  end

  def price
    encounter_items.map do |item|
      if item.stockout
        0
      else
        item.quantity * item.price_schedule.price
      end
    end.sum
  end

  def reimbursal_amount
    custom_reimbursal_amount || price
  end

  def started?
    submission_state == 'started'
  end

  def prepared?
    submission_state == 'prepared'
  end

  def submitted?
    submission_state == 'submitted'
  end

  def needs_revision?
    submission_state == 'needs_revision'
  end

  def pending?
    adjudication_state == 'pending'
  end

  def returned?
    adjudication_state == 'returned'
  end

  def revised?
    adjudication_state == 'revised'
  end

  def rejected?
    adjudication_state == 'rejected'
  end

  def approved?
    adjudication_state == 'approved'
  end

  def external?
    adjudication_state == 'external'
  end

  def reimbursed?
    reimbursement_id.present?
  end

  def resubmitted?
    # this call requires a look-up so the association should
    # be pre-fetched if calling on multiple encounters
    resubmitted_encounter.present?
  end

  def member_unconfirmed?
    !member.enrolled?
  end

  def member_inactive_at_time_of_service?
    member.inactive_at?(occurred_at)
  end

  def inbound_referral_unlinked?
    inbound_referral_date.present? && referral.blank?
  end

  def price_schedules_with_previous
    encounter_items.map do |encounter_item|
      price_schedule = encounter_item.price_schedule
      encounter_item.price_schedule_issued ? [price_schedule, price_schedule.previous_price_schedule] : [price_schedule]
    end.flatten
  end

  def get_total_by_accounting_group(accounting_groups)
    accounting_category_totals = accounting_groups.each_with_object({}) { |k, h| h[k] = 0 }

    encounter_items.each do |encounter_item|
      price_schedule = encounter_item.price_schedule
      billable = encounter_item.billable
      accounting_category = billable.accounting_group

      accounting_category_totals[accounting_category] += encounter_item.price
    end

    accounting_category_totals
  end

  # This field is going to be derived now.
  def adjudication_reason
    if adjudication_reason_category && adjudication_comment
      "#{adjudication_reason_category} - #{adjudication_comment}"
    else
      adjudication_reason_category || adjudication_comment
    end
  end

  class Claim
    attr_accessor :id, :encounters

    def initialize(id:, encounters:)
      @id = id
      # There is a scenario where `submitted_at` can be both `nil` and not null. i.e.:
      # - Encounter A: Hospital encounter that's returned
      # - Encounter B: Resubmission of encounter A as claims preparer. Not approved by facility head yet.
      # When facility head fetches this claim, it returns Encounter A and Encounter B, together.
      # Encounter A has `submitted_at` set, while Encounter B is merely prepared, so it has `submitted_at: nil`.
      # As a result, this sort_by needs to handle both null and non-null submitted_at, so that nils come first.
      @encounters = encounters.sort_by { |e| e.submitted_at.to_i }
    end

    def last_encounter
      @encounters.last
    end

    def last_submitted_at
      last_encounter.submitted_at
    end

    def originally_submitted_at
      @encounters.first.submitted_at
    end

    def self.sort_by_field(claims, sort_field, sort_direction)
      sorted_claims = claims.sort_by { |claim| [claim.last_encounter.send(sort_field), claim.id] }
      sorted_claims.reverse! if sort_direction == 'desc'
      sorted_claims
    end
  end

  def self.price_and_reimbursal_amount_sql
    <<-SQL
      WITH encounter_prices AS (
        SELECT
          encounter_items.encounter_id,
          SUM(CASE WHEN encounter_items.stockout THEN 0 ELSE encounter_items.quantity * price_schedules.price END) AS price
        FROM encounter_items
        JOIN price_schedules ON price_schedules.id = encounter_items.price_schedule_id
        GROUP BY encounter_items.encounter_id
      )
      SELECT encounters.id AS encounter_id, COALESCE(encounter_prices.price, 0) AS price, COALESCE(encounters.custom_reimbursal_amount, encounter_prices.price, 0) AS reimbursal_amount
      FROM encounters
      LEFT OUTER JOIN encounter_prices ON encounter_prices.encounter_id = encounters.id
    SQL
  end

  # TODO: convert dates to application timezone (unless we get rid of this code altogether)
  def self.where_inactive_member_at_time_of_service_sql
    "members.household_id IS NOT NULL
     AND (members.archived_at < encounters.occurred_at OR NOT EXISTS
        (#{HouseholdEnrollmentRecord.joins(:enrollment_period).where('household_enrollment_records.household_id = households.id')
                  .where('household_enrollment_records.enrolled_at <= encounters.occurred_at')
                  .where('encounters.occurred_at BETWEEN enrollment_periods.coverage_start_date AND enrollment_periods.coverage_end_date')
                  .to_sql}
        )
     )"
  end

  private

  def set_submitted_encounter_as_pending
    self.adjudication_state = 'pending' if submitted? && adjudication_state.nil?
  end

  def set_revised_encounter_as_revised
    revised_encounter.update_attribute(:adjudication_state, 'revised') if revised_encounter.present?
  end
end
