module DemoDataGenerator
  include ImportLists
  include DataGenerator

  ANNUAL_CONTRIBUTION_FEE = 3_000
  BENEFICIARY_FEE = 100

  def setup_initial_data
    # Create administrative divisions
    generate_administrative_divisions

    # Create providers
    district = AdministrativeDivision.find_by_level('province')
    (county1, county2) = AdministrativeDivision.where(parent_id: district.id).limit(2)

    create(:provider, name: "#{county1.name} Health Center", provider_type: 'health_center', administrative_division: county1)
    create(:provider, name: "#{county2.name} Health Center", provider_type: 'health_center', administrative_division: county2)
    create(:provider, name: "#{district.name} Hospital", provider_type: 'general_hospital', administrative_division: district)

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

  def generate_administrative_divisions
    country = AdministrativeDivision.create(name: 'Canada', level: 'country', code: 0)

    region1 = AdministrativeDivision.create(name: 'Western Region', level: 'region', code: 0, parent_id: country.id)
    region2 = AdministrativeDivision.create(name: 'Eastern Region', level: 'region', code: 1, parent_id: country.id)

    province1 = AdministrativeDivision.create(name: 'British Columbia', level: 'province', code: 0, parent_id: region1.id)
    province2 = AdministrativeDivision.create(name: 'Ontario', level: 'province', code: 0, parent_id: region2.id)

    district1 = AdministrativeDivision.create(name: 'Fraser Valley', level: 'district', code: 0, parent_id: province1.id)
    district2 = AdministrativeDivision.create(name: 'Metro Vancouver', level: 'district', code: 1, parent_id: province1.id)
    district3 = AdministrativeDivision.create(name: 'Toronto Division', level: 'district', code: 0, parent_id: province2.id)
    district4 = AdministrativeDivision.create(name: 'York County', level: 'district', code: 1, parent_id: province2.id)

    AdministrativeDivision.create(name: 'Williams Lake', level: 'municipality', code: 0, parent_id: district1.id)
    AdministrativeDivision.create(name: 'Kamloops', level: 'municipality', code: 1, parent_id: district1.id)
    AdministrativeDivision.create(name: 'Vancouver', level: 'municipality', code: 0, parent_id: district2.id)
    AdministrativeDivision.create(name: 'Richmond', level: 'municipality', code: 1, parent_id: district2.id)
    AdministrativeDivision.create(name: 'Toronto', level: 'municipality', code: 0, parent_id: district3.id)
    AdministrativeDivision.create(name: 'Markham', level: 'municipality', code: 1, parent_id: district3.id)
    AdministrativeDivision.create(name: 'East York', level: 'municipality', code: 0, parent_id: district4.id)
    AdministrativeDivision.create(name: 'North York', level: 'municipality', code: 1, parent_id: district4.id)
  end
end
