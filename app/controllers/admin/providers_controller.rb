include FormatterHelper
require 'csv'

module Admin
  class ProvidersController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    # def index
    #   super
    #   @resources = Provider.
    #     page(params[:page]).
    #     per(10)
    # end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   Provider.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
    def export
      providers = Provider.all.order(:id)
      @export = CSV.generate do |csv|
        csv << [
          'id',
          'name',
          'administrative_division_id',
          'provider_type',
          'diagnoses_group_id',
          'contracted',
        ]
        providers.map do |provider|
          csv << [
            provider.id,
            provider.name,
            provider.administrative_division_id,
            provider.provider_type,
            provider.diagnoses_group_id,
            provider.contracted,
          ]
        end
        csv
      end

      send_data @export, filename: "providers_#{FormatterHelper.format_time_now}.csv"
    end
  end
end

