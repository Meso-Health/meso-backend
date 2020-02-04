include FormatterHelper

class EnrollmentReportingStatsController < ApplicationController
  before_action :initialize_service!

  def index
    render json: @service.generate_stats
  end

  private

  def initialize_service!
    # The Representer is used to filter the params to pass through only the fields that are valid filters
    # and we use an OpenStruct as the reference object because the Representer is not related to a specific model
    representer = EnrollmentReportingStatsFilterRepresenter.new(OpenStruct.new)
    representer.from_hash(params)
    @service = EnrollmentReportingStatsService.new(representer.to_hash)
  end
end
