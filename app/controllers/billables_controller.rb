class BillablesController < ApplicationController
  def index
    provider = Provider.find(params[:provider_id])
    billables = provider.billables.active.includes(:price_schedules)
    most_recent_price_schedule_issued_at = PriceSchedule.where(provider: provider).maximum(:issued_at).to_i
    cache_key = "billables/query-#{billables.count}-#{billables.maximum(:updated_at).to_i}-#{most_recent_price_schedule_issued_at}"
    if stale?(billables, etag: cache_key)
      render json: BillableWithPriceScheduleRepresenter.for_collection.new(billables).to_json(provider_id: provider.id)
    end
  end

  def create
    provider = Provider.find(params[:provider_id])
    billable = provider.billables.new(active: true, reviewed: false)

    representer = BillableRepresenter.new(billable)
    representer.from_hash(params)
    billable.save_with_id_collision!

    render json: representer.to_json, status: :created
  end
end
