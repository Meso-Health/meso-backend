PaperTrail.without_versioning do
  include FactoryBot::Syntax::Methods
  include DemoDataGenerator

  # Create admin divisions, providers, billables, and diagnoses
  DemoDataGenerator.setup_initial_data

  # Add all regions to the pilot region
  AdministrativeDivision.where(level: 'region').each do |ad|
    create(:pilot_region, administrative_division: ad)
  end

  (hc1, hc2) = Provider.where(provider_type: 'health_center')
  hospital1 = Provider.find_by_provider_type('general_hospital')

  country = AdministrativeDivision.where(name: 'Canada').first
  region = AdministrativeDivision.where(name: 'Western Region').first
  province = AdministrativeDivision.where(name: 'British Columbia').first
  district = AdministrativeDivision.where(name: 'Metro Vancouver').first
  municipality = AdministrativeDivision.where(name: 'Vancouver').first

  # Create users
  create(:user, :system_admin, username: 'system_admin', password: 'password', name: 'Admin', administrative_division: region)
  demo_enroller = create(:user, :enrollment, username: 'demo_enroller', password: 'password', name: 'Demo Enroller', administrative_division: district)

  # Create enrollment periods
  create(:enrollment_period, start_date: 2.years.ago, end_date: 1.years.ago, administrative_division: province)
  create(:enrollment_period, start_date: 6.months.ago, end_date: 6.months.from_now, administrative_division: province)

  # Create households, members, enrollment records and payments
  [[municipality, demo_enroller]].each do |village, enroller|
    # Need to renew
    generate_household(village, enroller, household_size: 2, paying: true, renewed: false, include_member_photos: false)

    # Need to renew, with beneficiaries
    generate_household(village, enroller, household_size: 5, paying: true, renewed: false, include_member_photos: false)

    # Does not need to renew
    generate_household(village, enroller, household_size: 5, paying: true, renewed: true, include_member_photos: false)
  end

  payer_admin = create(:user, :payer_admin, username: 'payer_admin', name: 'Payer Admin', administrative_division: country)
  adjudication = create(:user, :adjudication, username: 'adjudication', name: 'Adjudication', administrative_division: region, adjudication_limit: 10_000)

  # Creating the hospital data out of the loop so that the referral references will exist
  hospital1_admin = create(:user, :provider_admin, username: 'hospital_admin', name: 'Hospital Admin', provider: hospital1)
  hospital1_identification = create(:user, :identification, username: 'hospital_identification', name: 'Hospital Identification', provider: hospital1)
  hospital1_submission = create(:user, :submission, username: 'hospital_submission', name: 'Hospital Submission', provider: hospital1)

  generate_hospital_id_events_and_partial_encounters(hospital1, hospital1_identification, hospital1_submission, hospital1_admin)
  generate_reimbursements(hospital1, hospital1_admin, adjudication, payer_admin)

  [[hc1, 'hc1', 'HealthCenter1'],
   [hc2, 'hc2', 'HealthCenter2']].each do |provider, username, name|
    provider_user = create(:user, :provider_admin, username: "#{username}_admin", name: "#{name} Admin", provider: provider)
    create(:user, :identification, username: "#{username}_identification", name: "#{name} Identification", provider: provider)
    create(:user, :submission, username: "#{username}_submission", name: "#{name} Submission", provider: provider)

    # Create id events and encounters
    generate_id_events_and_encounters(provider, provider_user, adjudication)

    # Create stockouts and referrals
    generate_stockouts_and_referrals(provider, provider_user, hospital1, hospital1_admin, adjudication)

    # Create reimbursements
    generate_reimbursements(provider, provider_user, adjudication, payer_admin)
  end

  # These are cards that have have been generated and physically printed, so we want to keep them around.
  card_ids_in_demo = %w[MSO355693 MSO001485 MSO002681 MSO004202 MSO006331 MSO007947 MSO010906 MSO016024 MSO018847 MSO021281 MSO024120 MSO027477 MSO027549 MSO035847 MSO039477 MSO041096 MSO047076 MSO048359 MSO056230 MSO059850 MSO060239 MSO065717 MSO067095 MSO073036 MSO073983 MSO080434 MSO088317 MSO091427 MSO091614 MSO093062 MSO095264 MSO095479 MSO099952 MSO100262 MSO105772 MSO107857 MSO108503 MSO109834 MSO114713 MSO115327 MSO115780 MSO117036 MSO123907 MSO125915 MSO130479 MSO131267 MSO134958 MSO143841 MSO143851 MSO144606 MSO144910 MSO149874 MSO150452 MSO150918 MSO151815 MSO153471 MSO153812 MSO155918 MSO162637 MSO164383 MSO164612 MSO167603 MSO169437 MSO170129 MSO174877 MSO181426 MSO184090 MSO184310 MSO186535 MSO187299 MSO187951 MSO188239 MSO193815 MSO196736 MSO197172 MSO201649 MSO202923 MSO206745 MSO207159 MSO210603 MSO211360 MSO219821 MSO222082 MSO222540 MSO224093 MSO225781 MSO226058 MSO228783 MSO229450 MSO231410 MSO234388 MSO236916 MSO236940 MSO240116 MSO245355 MSO246530 MSO246805 MSO251460 MSO251506 MSO253140 MSO259428 MSO261836 MSO263687 MSO278249 MSO278717 MSO279935 MSO284888 MSO285342 MSO286904 MSO287511 MSO289322 MSO289722 MSO289809 MSO291703 MSO293675 MSO296047 MSO296288 MSO297138 MSO297983 MSO298894 MSO299632 MSO300826 MSO308223 MSO313062 MSO313724 MSO315288 MSO316868 MSO316990 MSO319645 MSO320402 MSO328300 MSO335891 MSO342894 MSO345926 MSO348453 MSO349168 MSO351373 MSO353760 MSO354587 MSO357163 MSO359110 MSO360596 MSO362478 MSO367121 MSO371014 MSO371086 MSO371152 MSO373141 MSO376430 MSO380787 MSO381572 MSO382935 MSO385712 MSO391759 MSO399700 MSO399733 MSO406534 MSO416007 MSO417866 MSO420812 MSO426371 MSO426790 MSO428619 MSO430854 MSO435086 MSO436895 MSO445950 MSO446507 MSO448028 MSO450350 MSO451073 MSO452742 MSO454135 MSO456812 MSO457915 MSO459263 MSO462406 MSO463864 MSO466335 MSO466829 MSO471589 MSO472054 MSO473368 MSO476582 MSO483154 MSO484586 MSO484862 MSO487839 MSO489983 MSO490210 MSO490548 MSO491265 MSO491938 MSO492748 MSO493948 MSO494735 MSO498883 MSO507709 MSO515153 MSO518173 MSO522502 MSO522557 MSO524197 MSO525052 MSO526797 MSO527402 MSO528087 MSO542330 MSO542826 MSO546110 MSO547989 MSO549219 MSO550175 MSO553186 MSO555172 MSO559780 MSO560220 MSO561407 MSO561589 MSO563011 MSO564357 MSO565211 MSO568268 MSO568327 MSO576203 MSO580498 MSO581089 MSO581828 MSO584977 MSO587184 MSO589183 MSO594329 MSO598627 MSO600589 MSO606320 MSO607698 MSO608254 MSO612309 MSO614527 MSO616605 MSO624806 MSO626541 MSO626727 MSO632770 MSO633062 MSO633777 MSO634688 MSO637019 MSO639126 MSO640327 MSO641361 MSO641920 MSO644130 MSO645256 MSO645590 MSO651429 MSO653191 MSO653262 MSO653346 MSO653732 MSO654459 MSO656554 MSO664018 MSO665143 MSO667222 MSO667826 MSO669032 MSO671902 MSO674687 MSO676106 MSO677191 MSO678215 MSO681988 MSO686100 MSO687722 MSO690536 MSO691449 MSO692874 MSO693323 MSO696769 MSO699269 MSO701830 MSO704431 MSO707761 MSO711147 MSO717459 MSO721026 MSO721232 MSO721897 MSO722397 MSO727009 MSO728800 MSO728868 MSO732058 MSO732113 MSO732874 MSO733016 MSO736433 MSO739895 MSO740769 MSO741120 MSO742990 MSO744918 MSO746544 MSO748974 MSO754538 MSO758129 MSO758731 MSO762586 MSO764623 MSO771614 MSO774897 MSO777930 MSO780824 MSO780985 MSO785427 MSO790608 MSO790820 MSO793403 MSO794155 MSO796558 MSO798573 MSO809373 MSO810346 MSO811272 MSO817010 MSO817495 MSO822700 MSO823048 MSO825311 MSO826199 MSO827553 MSO832360 MSO837103 MSO837194 MSO841395 MSO841771 MSO842042 MSO843574 MSO845795 MSO846351 MSO846829 MSO849225 MSO849460 MSO849944 MSO850406 MSO851309 MSO852268 MSO853285 MSO855223 MSO855543 MSO863289 MSO865529 MSO870298 MSO873836 MSO883141 MSO889324 MSO890702 MSO891995 MSO892763 MSO896750 MSO897787 MSO901273 MSO901719 MSO906444 MSO906569 MSO907649 MSO909422 MSO913521 MSO914051 MSO916767 MSO921458 MSO924281 MSO925541 MSO928141 MSO931330 MSO932989 MSO935942 MSO938405 MSO940778 MSO941303 MSO941627 MSO943281 MSO944752 MSO948105 MSO953217 MSO953289 MSO954048 MSO959403 MSO961590 MSO961778 MSO962724 MSO965524 MSO966788 MSO976732 MSO976930 MSO978789 MSO979469 MSO990587 MSO996068 MSO996828 RWI046898 RWI057915 RWI227722 RWI227830 RWI304194 RWI409627 RWI415272 RWI431267 RWI440366 RWI476101 RWI556594 RWI572638 RWI587679 RWI602910 RWI610691 RWI670834 RWI702504 RWI776881 RWI862884 RWI872976 RWI917787 RWI918230 WTC038198 WTC040393 WTC218675 WTC415970 WTC481026 WTC722498 WTC757945 WTC779219 WTC812817 WTC943408].freeze

  # Make the cards for demo.
  generate_demo_cards_with_fixed_ids(card_ids_in_demo)
end
