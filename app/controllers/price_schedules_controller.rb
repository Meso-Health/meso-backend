class PriceSchedulesController < ApplicationController
  def create
    provider = Provider.find(params[:provider_id])
    new_price_schedule = provider.price_schedules.new
    representer = PriceScheduleRepresenter.new(new_price_schedule)
    representer.from_hash(params)

    new_price_schedule.save_with_id_collision!
    render json: representer.to_json, status: :created
  end
end
