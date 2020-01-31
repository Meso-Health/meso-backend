class MembersController < ApplicationController
  DEFAULT_PAGE_SIZE = 100
  MAX_PAGE_SIZE = 1000
  before_action :parse_params!, only: :index

  def index
    @most_recent_enrollment_period_id = EnrollmentPeriod.active_now&.first&.id
    administrative_division_ids = AdministrativeDivision.self_and_descendants_ids(@provider&.administrative_division)
    @members = Member
        .includes(household: :household_enrollment_records)
        .where(households: { administrative_division_id: administrative_division_ids })

    calculate_current_cache_key

    if @current_cache_key == @request_cache_key
      render json: {
        page_key: params[:page_key],
        has_more: false,
        members: []
      }
    else
      generate_member_page
      render json: {
        page_key: @encoded_page_key,
        has_more: @has_more,
        members: MemberRepresenter.for_collection.new(@members_page).to_hash(
          most_recent_enrollment_period_id: @most_recent_enrollment_period_id,
          mrn_key: @current_user.mrn_key
        )
      }
    end
  end

  def create
    member = Member.new
    representer = MemberRepresenter.new(member)
    representer.from_hash(params)
    member.set_medical_record_number(@current_user.mrn_key, params[:medical_record_number])
    member.set_card_id_to_nil_if_invalid
    member.save_with_id_collision!

    render json: representer.to_json(mrn_key: @current_user.mrn_key), status: :created
  end

  def update
    member = Member.find(params[:id])

    representer = MemberRepresenter.new(member)
    representer.from_hash(params)
    member.set_medical_record_number(@current_user.mrn_key, params[:medical_record_number])
    member.set_card_id_to_nil_if_invalid
    member.save!

    render json: representer.to_json(mrn_key: @current_user.mrn_key), status: :created
  end

  def search
    members = []
    if params.has_key?(:name) && params[:name].present?
      if params.has_key?(:administrative_division_id)
        members = Member.in_administrative_division(params[:administrative_division_id]).fuzzy_matching_name(params[:name])
      else
        members = Member.fuzzy_matching_name(params[:name]).limit(100)
      end
    elsif params.has_key?(:medical_record_number)
      mrn_key = @current_user.provider_id || params[:provider_id] || @current_user.mrn_key
      members = Member.filter_with_params(params.merge(mrn_key: mrn_key))
    end

    if members.present?
      render json: MemberRepresenter.for_collection.new(members).to_json(
        mrn_key: @current_user.mrn_key
      )
    else
      render json: []
    end
  end

  private

  def parse_params!
    @provider = @current_user.provider

    @limit = params[:limit] ? Integer(params[:limit]) : DEFAULT_PAGE_SIZE
    unless (1..MAX_PAGE_SIZE).cover?(@limit)
      ExceptionsApp.for(:bad_request).render(self)
      return
    end

    decode_page_key
  rescue JSON::ParserError, TypeError, ArgumentError
    ExceptionsApp.for(:bad_request).render(self)
  end

  def decode_page_key
    return unless params[:page_key]

    page_key = JSON.parse(Base64.decode64(params[:page_key]))
    @cursor = Cursor.from_hash(page_key['cursor']) if page_key['cursor']
    @request_cache_key = MemberCacheKey.from_hash(page_key['cache_key']) if page_key['cache_key']
    @request_next_cache_key = MemberCacheKey.from_hash(page_key['next_cache_key']) if page_key['next_cache_key']
  end

  # Defines a member cursor, which is simply the created_at and id of the last record the client has seen.
  # Store created_at as a rational since milliseconds are lost when stored as string, integer, or float,
  # leading to query and comparison issues.
  class Cursor
    attr_accessor :created_at, :id

    def initialize(created_at:, id:)
      @created_at = created_at
      @id = id
    end

    def self.from_hash(hash)
      new(
        created_at: Rational(hash['created_at']),
        id: hash['id']
      )
    end

    def to_hash
      {
        created_at: @created_at,
        id: @id
      }
    end
  end

  # Defines a member cache key, which is the last snapshot of the DB that the client has downloaded.
  # Store timestamps as rationals since milliseconds are lost when stored as string, integer, or float,
  # leading to query and comparison issues.
  # We do not need to consider counts for now since we are never deleting member or household enrollment record records.
  class MemberCacheKey
    attr_accessor :member_last_updated_at,
                  :household_enrollment_record_last_updated_at,
                  :enrollment_period_id

    def initialize(member_last_updated_at:,
                   household_enrollment_record_last_updated_at:,
                   enrollment_period_id:)
      @member_last_updated_at = member_last_updated_at
      @household_enrollment_record_last_updated_at = household_enrollment_record_last_updated_at
      @enrollment_period_id = enrollment_period_id
    end

    def self.from_hash(hash)
      new(
        member_last_updated_at: Rational(hash['member_last_updated_at']),
        household_enrollment_record_last_updated_at: Rational(hash['household_enrollment_record_last_updated_at']),
        enrollment_period_id: hash['enrollment_period_id']
      )
    end

    def to_hash
      {
        member_last_updated_at: @member_last_updated_at,
        household_enrollment_record_last_updated_at: @household_enrollment_record_last_updated_at,
        enrollment_period_id: @enrollment_period_id
      }
    end

    def ==(o)
      o.class == self.class && o.state == state
    end

    protected

    def state
      [@member_last_updated_at, @household_enrollment_record_last_updated_at, @enrollment_period_id]
    end
  end

  # Filters for only members that could have changed since the cache key specified in the client request
  def filter_for_updated_members
    return if @request_cache_key.enrollment_period_id != @current_cache_key.enrollment_period_id

    @members = @members.where('members.updated_at > ?', Time.zone.at(@request_cache_key.member_last_updated_at))
                 .or(@members.where('household_enrollment_records.updated_at > ?', Time.zone.at(@request_cache_key.household_enrollment_record_last_updated_at)))
  end

  # Calculates the next page of members and whether more are available.
  # The limit (or a default value) ensures the query doesn't return more than a page of records.
  # If the cursor values are non-nil, they are used to offset the start of the page.
  def generate_member_page
    filter_for_updated_members if @request_cache_key
    members_to_return = @members.order('members.created_at ASC, members.id ASC')

    if @cursor
      members_to_return = members_to_return.where(
        '(members.created_at, members.id) > (?, ?)',
        Time.zone.at(@cursor.created_at),
        @cursor.id
      )
    end

    @members_page = members_to_return.limit(@limit).preload_photo
    @has_more = members_to_return.count > @limit
    generate_page_key
  end

  # Embeds the cursor, cache key, and next cache key into the page key hash.
  def generate_page_key
    if @has_more
      cursor = Cursor.new(created_at: @members_page.last.created_at.to_r, id: @members_page.last.id)
      cache_key = @request_cache_key
      next_cache_key = @request_next_cache_key || @current_cache_key
    else
      cursor = nil
      cache_key = @current_cache_key
      next_cache_key = nil
    end

    page_key = {
      cursor: cursor&.to_hash,
      cache_key: cache_key&.to_hash,
      next_cache_key: next_cache_key&.to_hash
    }

    @encoded_page_key = Base64.strict_encode64(page_key.to_json)
  end

  def calculate_current_cache_key
    member_household_ids = @members.pluck(:household_id)
    member_household_enrollment_records = HouseholdEnrollmentRecord.where(household_id: member_household_ids)

    @current_cache_key = MemberCacheKey.new(
      member_last_updated_at: @members.maximum(:updated_at).to_r,
      household_enrollment_record_last_updated_at: member_household_enrollment_records.maximum(:updated_at).to_r,
      enrollment_period_id: @most_recent_enrollment_period_id
    )
  end
end
