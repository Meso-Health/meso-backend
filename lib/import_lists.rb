require 'csv'
require 'open-uri'

module ImportLists

  def import_billables(csv_path)
    file = open(csv_path)
    billables = CSV.read(file.path); true
    billables.shift # remove header row

    billables.each do |row|
      is_health_center_billable = row[6] == 'Y'
      is_hospital_billable = row[7] == 'Y'
      billable = Billable.create(
          type: row[0],
          name: row[1],
          composition: row[2],
          unit: row[3],
          accounting_group: row[4]
      )
      if is_health_center_billable
        Provider.where(provider_type: 'health_center').each do |provider|
          PriceSchedule.create(
            provider_id: provider.id,
            billable_id: billable.id,
            issued_at: Time.zone.now,
            price: row[5].to_i
            # ^^^ TODO: If prices differ across facilities, figure out a way represent that in a csv import.
            # How we design the admin panel (how they import billables, with prices) should inform how we import
            # these in the seed file. For now, let's just assume the price listed in the csv is the price for all providers.
          )
        end
      end

      if is_hospital_billable
        Provider.where(provider_type: ['primary_hospital', 'general_hospital', 'tertiary_hospital']).each do |provider|
          PriceSchedule.create(
            provider_id: provider.id,
            billable_id: billable.id,
            issued_at: Time.zone.now,
            price: row[5].to_i
          )
        end
      end
    end
  end

  HEADER_ROW_NUMBER = 6
  FIRST_ROW_WITH_DATA = 7
  def import_diagnoses(csv_path)
    file = open(csv_path)
    diagnoses = CSV.read(file.path); true
    header_row = diagnoses[HEADER_ROW_NUMBER]

    column_to_field = {
      'Extended ID' => 2,
      'Compact ID' => 3,
      'Mini ID' => 4,
      'Description' => 7,
      'Alias1' => 8,
      'Alias2' => 9,
      'Alias3' => 10,
      'HMIS Diagnosis' => 14
    }

    # Create the three lists.
    mini_diagnoses_group = DiagnosesGroup.new(name: 'mini')
    mini_diagnoses_group.save

    compact_diagnoses_group = DiagnosesGroup.new(name: 'compact')
    compact_diagnoses_group.save

    extended_diagnoses_group = DiagnosesGroup.new(name: 'extended')
    extended_diagnoses_group.save

    diagnoses[FIRST_ROW_WITH_DATA..-1].each do |row|
      # Figure out the right group to put the diagnosis into.
      diagnoses_groups = []
      if row[column_to_field['Mini ID']].present?
        diagnoses_groups.push(mini_diagnoses_group)
      end

      if row[column_to_field['Compact ID']].present?
        diagnoses_groups.push(compact_diagnoses_group)
      end

      if row[column_to_field['Extended ID']].present?
        diagnoses_groups.push(extended_diagnoses_group)
      end

      description = row[column_to_field['Description']]
      search_aliases = [
        row[column_to_field['Alias1']],
        row[column_to_field['Alias2']],
        row[column_to_field['Alias3']],
        row[column_to_field['HMIS Diagnosis']]
      ].compact

      # Create the diagnosis. Diagnosis.id auto-generated so no need to fill it in.
      diagnosis = Diagnosis.new(
        description: description,
        search_aliases: search_aliases.map(&:strip)
      )
      diagnosis.save

      # Assign the diagnosis to the right groups.
      diagnosis.diagnoses_groups = diagnoses_groups
      diagnosis.save
    end
  end
end
