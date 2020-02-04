include ImportLists
include DataGenerator

module UgandaDataGenerator
  UGANDAN_FEMALE_NAMES = [
    'Florence P Kisembo', 'Joan Q Muhenda', 'Sharon B Byaitaka', 'Janet I Gonza',
    'Alice G Balikuraira', 'Catherine A Kabonesa', 'Rose P Baingama', 'Brenda R Komuntale',
    'Teresa K Nyangoma', 'Vicatoria T Muhenda', 'Imelda V Nsungwa', 'Evelyn I Sabiti',
    'Josephine E Mugisa', 'Nancy J Bagamba', 'Priscilla N Baingama'
  ].freeze

  UGANDAN_MALE_NAMES = [
    'John P Kabonesa', 'Moses J Byangireeka', 'Daniel M Alikuraira', 'Dennis D Kugonza',
    'Patrick Mwesige', 'Emmanual P Kiho', 'Jacob E Sabiti', 'Elijah J Byanruhanga',
    'Frank E Balinda', 'Jonathan F Irumba', 'Isaac J Bagamba', 'Robert I Muhenda',
    'George R Nyakoojo', 'Allan G Karwana', 'Solomon A Mugisa'
  ].freeze

  ANNUAL_CONTRIBUTION_FEE = 3_000
  BENEFICIARY_FEE = 100

  def setup_initial_data
    # Create administrative divisions
    generate_administrative_divisions

    # Create providers
    rwibaale = AdministrativeDivision.where(name: 'Rwibaale').first
    kyenjojo = AdministrativeDivision.where(name: 'Kyenjojo').first

    create(:provider, name: "Rwibaale Health Center", provider_type: 'health_center', administrative_division: rwibaale)
    create(:provider, name: "Kyenjojo Health Center", provider_type: 'health_center', administrative_division: kyenjojo)
    create(:provider, name: "Fort Portal Hospital", provider_type: 'general_hospital', administrative_division: kyenjojo)

    # Create billables
    import_billables('scripts/demo/lists/billables.csv')
    # Create diagnoses
    import_diagnoses('scripts/demo/lists/diagnoses.csv')

    Provider.where(provider_type: 'health_center').update_all(diagnoses_group_id: DiagnosesGroup.find_by_name('mini').id)
    Provider.where(provider_type: 'primary_hospital').update_all(diagnoses_group_id: DiagnosesGroup.find_by_name('compact').id)
    Provider.where(provider_type: 'general_hospital').update_all(diagnoses_group_id: DiagnosesGroup.find_by_name('extended').id)
    Provider.where(provider_type: 'tertiary_hospital').update_all(diagnoses_group_id: DiagnosesGroup.find_by_name('extended').id)
  end

  def generate_demo_cards_with_fixed_ids(card_ids)
    generate_cards_with_fixed_ids(card_ids, prefix: 'MSO')
  end

  def generate_ugandan_household(village, enroller, household_size:, paying:, renewed:, include_member_photos:)
    raise ArgumentError, 'Household size must be 1 or more' if household_size < 1

    # Generate household and original household enrollment record (set to have been created during first enrollment period)
    original_enrollment_period = EnrollmentPeriod.inactive.first
    original_enrolled_at = rand(original_enrollment_period.start_date..original_enrollment_period.end_date)
    household = create(:household, administrative_division: village, enrolled_at: original_enrolled_at)
    original_enrollment = create(
      :household_enrollment_record, household: household, administrative_division: village,
      enrollment_period: original_enrollment_period, enrolled_at: original_enrolled_at, user: enroller, paying: paying, renewal: false
    )
    if paying
      create(:membership_payment, household_enrollment_record: original_enrollment, annual_contribution_fee: ANNUAL_CONTRIBUTION_FEE, qualifying_beneficiaries_fee: BENEFICIARY_FEE * household_size)
    end

    # Generate members and member enrollment records
    generate_ugandan_household_members(household, original_enrollment_period, enroller, household_size: household_size, include_member_photos: include_member_photos)

    # For renewed households, generate additional household enrollment record for the current enrollment period
    if renewed
      current_enrollment_period = EnrollmentPeriod.active_now.first
      # Ensure renewals occur within past week so that renewed households appear in recently updated page in Enrollment App
      renewed_at = rand(1.week.ago.to_date..Time.zone.now.to_date)
      renewal = create(
        :household_enrollment_record, household: household, administrative_division: village,
        enrollment_period: current_enrollment_period, enrolled_at: renewed_at, user: enroller, paying: paying, renewal: true
      )
      if paying
        create(:membership_payment, household_enrollment_record: renewal, annual_contribution_fee: ANNUAL_CONTRIBUTION_FEE)
      end
    end
  end

  def generate_ugandan_household_members(household, enrollment_period, enroller, household_size:, include_member_photos:)
    head_of_household_gender = %w[M F].sample

    household_size.times do |i|
      member_attributes = {
        household: household,
        enrolled_at: household.enrolled_at,
        membership_number: nil, # will be automatically assigned upon creation of member enrollment record
        card: Card.unassigned.order(:id).first # assign cards in id order
      }
      member_attributes[:photo_id] = nil unless include_member_photos
      member_attributes[:full_name] = (head_of_household_gender == 'M') ? UGANDAN_MALE_NAMES.sample : UGANDAN_FEMALE_NAMES.sample

      member =
        case i
        when 0
          create(:member, :head_of_household, gender: head_of_household_gender, **member_attributes)
        when 1
          create(:member, :spouse, **member_attributes)
        else
          create(:member, :beneficiary, **member_attributes)
        end

      # .reload is necessary to refresh the member's household so that it reflects newly assigned membership numbers
      # (specifically so that household.assigned_membership_numbers? works as intended and membership numbers are generated properly)
      create(:member_enrollment_record, member: member.reload, enrollment_period: enrollment_period, user: enroller)
    end
  end

  def generate_administrative_divisions
    country = AdministrativeDivision.create(name: 'Uganda', level: 'country', code: 0)
    region = AdministrativeDivision.create(name: 'Western Region', level: 'region', code: 0, parent_id: country.id)
    district = AdministrativeDivision.create(name: 'Kyenjojo', level: 'district', code: 0, parent_id: region.id)

    rwibaale = AdministrativeDivision.create(name: 'Rwibaale', level: 'village', code: 0, parent_id: district.id)
    AdministrativeDivision.create(name: 'Kabwera', level: 'subvillage', code: 0, parent_id: rwibaale.id)
    AdministrativeDivision.create(name: 'Kafuuzi', level: 'subvillage', code: 1, parent_id: rwibaale.id)
    AdministrativeDivision.create(name: 'Kanyegarmire', level: 'subvillage', code: 2, parent_id: rwibaale.id)
    AdministrativeDivision.create(name: 'Misenyi', level: 'subvillage', code: 3, parent_id: rwibaale.id)

    #AdministrativeDivision.create(name: 'Mbale', level: 'district', code: 1, parent_id: region.id)
    #AdministrativeDivision.create(name: 'Mbarara', level: 'district', code: 2, parent_id: region.id)
    #AdministrativeDivision.create(name: 'Maniyango', level: 'district', code: 3, parent_id: region.id)

    #AdministrativeDivision.create(name: 'Kisojo', level: 'village', code: 1, parent_id: district.id)
    #AdministrativeDivision.create(name: 'Kigunda', level: 'village', code: 2, parent_id: district.id)
    #AdministrativeDivision.create(name: 'Matiri', level: 'village', code: 3, parent_id: district.id)
  end
end
