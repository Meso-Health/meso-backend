require 'csv'

class ReimbursementReportingController < ApplicationController
  before_action :parse_params!

  def csv
    @export = @service.generate_csv
    send_data @export, filename: 'reimbursement_report.csv'
  end

  private

  def parse_params!
    @reimbursement_id = params[:reimbursement_id]
    @service = ReimbursementReportingService.new(@reimbursement_id)
  end
end
