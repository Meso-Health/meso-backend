include FormatterHelper
require 'csv'

module Admin
  class BillablesController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = Billable.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   Billable.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
    def import
      csv_file = params[:file]

      error = nil
      current_line = 1 # Used for error reporting.
      begin
        ActiveRecord::Base.transaction do
          if csv_file
            billables = CSV.read(csv_file.path, encoding: "ISO8859-1:utf-8")
            header_row = billables.shift # Shift the header row out of the way.
            column_to_field = {
              'id' => 0,
              'type' => 1,
              'name' => 2,
              'composition' => 3,
              'unit' => 4,
              'accounting_group' => 5,
              'active' => 6,
            }
            billables.each do |row|
              # If there is an ID that means the billable already exists.
              id = row[column_to_field['id']]
              type = row[column_to_field['type']]
              name = row[column_to_field['name']]
              composition = row[column_to_field['composition']]
              unit = row[column_to_field['unit']]
              accounting_group = row[column_to_field['accounting_group']]
              active = row[column_to_field['active']]

              if id.blank?
                # Create a new billable
                billable = Billable.new(
                  type: type,
                  name: name,
                  composition: composition,
                  unit: unit,
                  accounting_group: accounting_group,
                  active: active,
                )
                billable.save
              else
                billable = Billable.find_by_id(id)
                if billable
                  billable.update_attributes(
                    type: type,
                    name: name,
                    composition: composition,
                    unit: unit,
                    accounting_group: accounting_group,
                    active: active,
                  )
                else
                  raise "Billable with #{id} is not found in DB. Please keep it blank if it is a new one."
                end
              end
              current_line = current_line + 1
            end
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
          flash[:success] = 'Billables have been updated'
        end

        redirect_to(
          admin_billables_path
        )
    end

    def export
      billables = Billable.all.order(active: :desc)
      @export = CSV.generate do |csv|
        csv << [
          'id',
          'type',
          'name',
          'composition',
          'unit',
          'accounting_group',
          'active',
        ]
        rows = billables.map do |billable|
          csv << [
            billable.id,
            billable.type,
            billable.name,
            billable.composition,
            billable.unit,
            billable.accounting_group,
            billable.active,
          ]
        end
        csv
      end

      send_data @export, filename: "billables_#{FormatterHelper.format_time_now}.csv"
    end
  end
end
