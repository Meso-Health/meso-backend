class ProviderReportingStatsController < ApplicationController
  before_action :parse_params!

  def show
    render json: @service.stats
  end

  private

  def parse_params!
    provider_id = params[:provider_id]&.to_i
    start_date = params[:start_date]
    end_date = params[:end_date]
    @service = ProviderReportingStatsService.new(provider_id, start_date, end_date)
  end
end
