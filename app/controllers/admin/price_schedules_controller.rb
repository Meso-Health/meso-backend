include FormatterHelper
require 'csv'

module Admin
  class PriceSchedulesController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = PriceSchedule.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   PriceSchedule.find_by!(slug: param)
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
            price_schedules = CSV.read(csv_file.path, encoding: "ISO8859-1:utf-8")
            header_row = price_schedules.shift # Shift the header row out of the way.
            column_to_field = {
              'billable_id' => 0,
              'provider_id' => 1,
              'price' => 2,
            }

            price_schedules_to_insert = []
            price_schedules.each do |row|
              billable_id = row[column_to_field['billable_id']]
              provider_id = row[column_to_field['provider_id']]&.to_i
              price = row[column_to_field['price']]&.to_i

              billable = Billable.find(billable_id)
              provider = Provider.find(provider_id)
              
              # No need to make any changes if the price is the same or nil.
              active_price_schedule = billable.active_price_schedule_for_provider(provider_id)
              if active_price_schedule&.price != price
                price_schedules_to_insert.push(PriceSchedule.new(
                  billable: billable,
                  provider: provider,
                  price: price,
                  issued_at: Time.zone.now,
                  previous_price_schedule: active_price_schedule, # This can be nil.
                ))
              end

              current_line = current_line + 1
            end

            # Bulk upsert to improve performance.
            PriceSchedule.import! price_schedules_to_insert
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
          flash[:success] = 'Price Schedules have been updated'
        end

        redirect_to(
          admin_price_schedules_path
        )
    end

    def export
      provider_id = params[:provider_id]&.to_i
      @export = CSV.generate do |csv|
        csv << [
          'billable_id',
          'provider_id',
          'price',
        ]
        price_schedules = PriceSchedule.active
        if provider_id
          price_schedules = PriceSchedule.active.where(provider_id: provider_id)
        else
          Rollbar.error "provider_id is null while getting price schedule export. #{params.as_json}"
        end
        price_schedules.each do |price_schedule|
          csv << [
            price_schedule.billable_id,
            price_schedule.provider_id,
            price_schedule.price
          ]
        end
        csv
      end

      send_data @export, filename: "price_schedules_#{FormatterHelper.format_time_now}.csv"
    end

    def create
      resource = resource_class.new(resource_params.except(:count))
      authorize_resource(resource)

      # Create the cards in batch as a transaction.
      ActiveRecord::Base.transaction do
        price_schedule = resource
        billable_id = price_schedule.billable_id
        provider_id = price_schedule.provider_id
        billable = Billable.find(billable_id)
        active_price_schedule = billable.active_price_schedule_for_provider(provider_id)

        resource.previous_price_schedule = active_price_schedule
        resource.issued_at = Time.zone.now
        if resource.save
          redirect_to(
            [namespace, resource],
            notice: translate_with_resource("create.success"),
          )
          return
        end
      end
    
      render :new, locals: {
        page: Administrate::Page::Form.new(dashboard, resource),
      }
    end
  end
end

