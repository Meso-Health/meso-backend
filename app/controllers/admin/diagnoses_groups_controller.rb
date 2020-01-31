require 'csv'

module Admin
  class DiagnosesGroupsController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = DiagnosesGroup.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   DiagnosesGroup.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
    def export
      diagnoses_group_id = params[:diagnoses_group_id].to_i
      diagnoses_group = DiagnosesGroup.find(diagnoses_group_id)
      @export = CSV.generate do |csv|
        csv << [
          'id',
          'description',
          'search_aliases',
          'active'
        ]
        rows = diagnoses_group.diagnoses.order('id').map do |diagnosis|
          csv << [diagnosis.id, diagnosis.description, diagnosis.search_aliases, diagnosis.active]
        end
        csv
      end

      send_data @export, filename: "diagnoses_group_#{diagnoses_group_id}.csv"
    end

    def import
      diagnoses_group_id = params[:diagnoses_group_id].to_i
      diagnoses_group = DiagnosesGroup.find(diagnoses_group_id)
      csv_file = params[:file]

      error = nil
      current_line = 1 # Used for error reporting.
      begin
        ActiveRecord::Base.transaction do
          if csv_file
            diagnoses = CSV.read(csv_file.path, encoding: "ISO8859-1:utf-8")
            header_row = diagnoses.shift # Shift the header row out of the way.
            column_to_field = {
              'id' => 0,
              'description' => 1,
              'search_aliases' => 2,
              'active' => 3
            }
            updated_diagnoses = []
            diagnoses.each do |row|
              # If there is an ID that means the diagnosis already exists.
              id = row[column_to_field['id']]
              description = row[column_to_field['description']]
              search_aliases = row[column_to_field['search_aliases']]
              active = row[column_to_field['active']]

              if id.blank?
                # Create a new diagnosis
                diagnosis = Diagnosis.new(
                  description: description,
                  search_aliases: JSON.parse(search_aliases) || [], # JSON.parse converts a json array in string form to an array.
                  active: active
                )
                diagnosis.save
                updated_diagnoses.push(diagnosis)
              else
                diagnosis = Diagnosis.find_by_id(id)
                if diagnosis
                  diagnosis.update_attributes(
                    description: description,
                    search_aliases: JSON.parse(search_aliases), # JSON.parse converts a json array in string form to an array.
                    active: active
                  )
                  updated_diagnoses.push(diagnosis)
                else
                  raise "Diagnosis with #{id} is not found in DB. Please keep it blank if it is a new one."
                end
              end
              current_line = current_line + 1
            end

            # The diagnoses not in the csv will be removed from the group.
            diagnoses_group.diagnoses = updated_diagnoses
            diagnoses_group.save
          end
        end
        rescue => e
          error = "Error: #{e.message} CSV Line: #{current_line}"
        end

        # We need to first clear the session before adding flash because the session will automatically store the request
        # which is beyond the 4kb limit for the CookieStore (due to the csv file). As a result, we need to clear session first
        # In order to avoid CookieJar overflow exception.
        session.clear
        if error.present?
          flash[:error] = error
        else
          flash[:success] = 'Diagnoses group has been updated'
        end

        redirect_to(
          admin_diagnoses_group_path(diagnoses_group)
        )
    end
  end
end
