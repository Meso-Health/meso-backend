include FormatterHelper
require 'csv'

class ClaimsController < PaginationController
  DEFAULT_SORT_FIELD = 'submitted_at'
  DEFAULT_SORT_DIRECTION = 'desc'
  SORTABLE_FIELDS = %w[claim_id provider_id occurred_at submitted_at adjudicated_at visit_type reimbursal_amount updated_at]
  SEARCHABLE_FIELDS = %w[claim_id membership_number]
  CLAIM_FLAGS = %w[all no_flags unconfirmed_member inactive_member unlinked_inbound_referral]
  before_action :parse_member_claims_params!, only: :member_claims
  before_action :parse_filter_params!, only: :index
  before_action :parse_search_params!, only: :index

  def index
    @query = Encounter.latest.load_costs
    filter_claims
    @query = @query.search_by_field(@search_field, @search_query)
    @query = @query.sort_by_field(@sort_field, @sort_direction)
    @total_claims_count = @query.length

    generate_claims_page

    respond_to do |format|
      format.json do
        render json: {
          total: @total_claims_count,
          prev_url: @prev_url,
          next_url: @next_url,
          claims: ClaimRepresenter.for_collection.new(@current_claims_page).to_hash(mrn_key: @current_user.mrn_key)
        }
      end
      format.csv do
        provider_designation = @provider&.name || @provider_type || 'all_providers'
        start_date = @start_date || @current_claims_page.last&.last_submitted_at
        end_date = @end_date || @current_claims_page.first&.last_submitted_at
        formatted_start_date = FormatterHelper.format_date(start_date) if start_date
        formatted_end_date = FormatterHelper.format_date(end_date) if end_date
        @current_claims_page = @current_claims_page.sort_by { |x| x.last_encounter.member.membership_number } if @adjudication_state == 'external'

        @export = ClaimReportingService.new(@current_claims_page, provider_designation, formatted_start_date, formatted_end_date).generate_csv
        send_data @export, filename: "#{provider_designation}_claim_report_#{formatted_start_date}-#{formatted_end_date}.csv"
      end
    end
  end

  def show
    encounter = Encounter.find(params[:encounter_id])
    claim_encounters = Encounter.preloaded.where(claim_id: encounter.claim_id)
    claim = Encounter.to_claims(claim_encounters).first

    render json: ClaimRepresenter.new(claim).to_json
  end

  # TODO: combine with /index
  def member_claims
    leaf_encounters = Encounter.latest.submitted.where(member_id: params[:id])
    leaf_encounters = leaf_encounters.where('encounters.submitted_at >= ?', @start_date) if @start_date
    leaf_encounters = leaf_encounters.where('encounters.submitted_at <= ?', @end_date) if @end_date
    all_matching_encounters = Encounter.where(claim_id: leaf_encounters.pluck(:claim_id))
    claims = Encounter.to_claims(all_matching_encounters)
    render json: ClaimRepresenter.for_collection.new(claims).to_hash
  end

  private

  def parse_member_claims_params!
    @start_date = Time.zone.parse(params[:start_date]) if params[:start_date]
    @end_date = Time.zone.parse(params[:end_date]) if params[:end_date]
  rescue TypeError, ArgumentError
    ExceptionsApp.for(:bad_request).render(self)
  end

  def parse_filter_params!
    @returned_to_preparer = ActiveModel::Type::Boolean.new.cast(params[:returned_to_preparer])
    @adjudication_state = params[:adjudication_state]
    unless @adjudication_state.nil? || Encounter::ADJUDICATION_STATES.include?(@adjudication_state)
      ExceptionsApp.for(:bad_request).render(self)
      return
    end

    @submission_state = params[:submission_state] || 'submitted'
    unless Encounter::SUBMISSION_STATES.include?(@submission_state)
      ExceptionsApp.for(:bad_request).render(self)
      return
    end

    @provider_type = params[:provider_type]
    if @current_user.provider_id.present?
      @provider = @current_user.provider

      if params[:provider_id] && @current_user.provider_id != params[:provider_id].to_i
        Rollbar.error "Request from a provider user contains a different provider_id. Params: #{params.as_json}"
        ExceptionsApp.for(:forbidden).render(self)
        return
      end
    else
      @provider = Provider.find(params[:provider_id]) if params[:provider_id]
    end

    @member_admin_division = AdministrativeDivision.find(params[:member_admin_division_id]) if params[:member_admin_division_id]

    @start_date = Time.zone.parse(params[:start_date]) if params[:start_date]
    @end_date = Time.zone.parse(params[:end_date]) if params[:end_date]
    @min_amount = Integer(params[:min_amount]) if params[:min_amount]
    @max_amount = Integer(params[:max_amount]) if params[:max_amount]

    @resubmitted = ActiveModel::Type::Boolean.new.cast(params[:resubmitted])
    @audited = ActiveModel::Type::Boolean.new.cast(params[:audited])
    @paid = ActiveModel::Type::Boolean.new.cast(params[:paid])
    @flag = params[:flag]
    unless @flag.nil? || CLAIM_FLAGS.include?(@flag)
      ExceptionsApp.for(:bad_request).render(self)
      return
    end
  rescue TypeError, ArgumentError
    ExceptionsApp.for(:bad_request).render(self)
  end

  def parse_search_params!
    @search_field = params[:search_field]
    unless @search_field.nil? || SEARCHABLE_FIELDS.include?(@search_field)
      ExceptionsApp.for(:bad_request).render(self)
      return
    end

    @search_query = params[:search_query]
    unless @search_field.present? == @search_query.present?
      ExceptionsApp.for(:bad_request).render(self)
      return
    end

    @search_query = @search_query.downcase if @search_field == 'claim_id'
  end

  def filter_claims
    if @returned_to_preparer
      @query = @query.where("encounters.adjudication_state = 'returned' OR encounters.submission_state = 'needs_revision'")
    else
      @query = @query.where(adjudication_state: @adjudication_state) if @adjudication_state
      @query = @query.where(submission_state: @submission_state) if @submission_state
    end

    @query = @query.joins(:provider).where(providers: { provider_type: @provider_type }) if @provider_type
    @query = @query.where(provider: @provider) if @provider
    if @member_admin_division
      admin_division_ids = AdministrativeDivision.self_and_descendants_ids(@member_admin_division)
      @query = @query.joins(member: :household).where(households: { administrative_division_id: admin_division_ids })
    end

    @query = @query.where('encounters.submitted_at >= ?', @start_date) if @start_date
    @query = @query.where('encounters.submitted_at <= ?', @end_date) if @end_date
    @query = @query.where('encounter_costs.reimbursal_amount >= ?', @min_amount) if @min_amount
    @query = @query.where('encounter_costs.reimbursal_amount <= ?', @max_amount) if @max_amount

    @query = @resubmitted ? @query.resubmitted : @query.not_resubmitted unless @resubmitted.nil?
    @query = @audited ? @query.audited : @query.not_audited unless @audited.nil?
    @query = @paid ? @query.paid : @query.unpaid unless @paid.nil?

    case @flag
    when 'all'
      @query = @query.all_flagged
    when 'no_flags'
      @query = @query.not_flagged
    when 'unconfirmed_member'
      @query = @query.with_unconfirmed_member
    when 'inactive_member'
      @query = @query.with_inactive_member_at_time_of_service
    when 'unlinked_inbound_referral'
      @query = @query.with_unlinked_inbound_referral
    end
  end

  # Calculates the next page of claims and whether more are available.
  # The limit (or a default value) ensures the query doesn't return more than a page of records.
  # If the cursor values are non-nil, they are used to offset the start of the page.
  def generate_claims_page
    if @starting_after_cursor
      cursor_encounter = Encounter.where(claim_id: @starting_after_cursor).latest.first
      @query = @query.starting_after(cursor_encounter, @sort_field, @sort_direction)
    elsif @ending_before_cursor
      cursor_encounter = Encounter.where(claim_id: @ending_before_cursor).latest.first
      @query = @query.ending_before(cursor_encounter, @sort_field, @sort_direction)
    end

    @remaining_claims_count = @query.length
    current_claim_ids = @query.limit(@limit).map(&:claim_id)
    # perform second query to fetch full encounter chain for each claim
    @current_claims_page = Encounter.to_claims(Encounter.preloaded.where(claim_id: current_claim_ids))
    # sort claims by proper fields since ordering gets lost during previous step
    @current_claims_page = Encounter::Claim.sort_by_field(@current_claims_page, @sort_field, @sort_direction)

    # if ending_before_cursor is specified, then @query and remaining_claims_count represent the claims BEFORE the current page.
    # otherwise, they represent the claims AFTER the current page.
    if @ending_before_cursor
      generate_prev_url if @remaining_claims_count > @limit
      generate_next_url if @remaining_claims_count < @total_claims_count
    else
      generate_prev_url if @remaining_claims_count < @total_claims_count
      generate_next_url if @remaining_claims_count > @limit
    end
  end

  def get_current_params
    {
      limit: @limit,
      adjudication_state: @adjudication_state,
      submission_state: @submission_state,
      provider_type: @provider_type,
      provider_id: @provider&.id,
      member_admin_division_id: @member_admin_division&.id,
      start_date: @start_date,
      end_date: @end_date,
      min_amount: @min_amount,
      max_amount: @max_amount,
      resubmitted: @resubmitted,
      audited: @audited,
      paid: @paid,
      search_field: @search_field,
      search_query: @search_query,
      sort: @sort,
      returned_to_preparer: @returned_to_preparer
    }.compact # removes keys with nil values since otherwise they would be converted to 'nil' strings
  end

  def generate_prev_url
    path_params = get_current_params.merge!(ending_before: Base64.strict_encode64(@current_claims_page.first.id))
    @prev_url = claims_path(path_params)
  end

  def generate_next_url
    path_params = get_current_params.merge!(starting_after: Base64.strict_encode64(@current_claims_page.last.id))
    @next_url = claims_path(path_params)
  end
end
