class TransfersController < ApplicationController
  before_action :require_system_admin!

  def create
    transfer = Transfer.new(user: @current_user)

    representer = TransferRepresenter.new(transfer)
    representer.from_hash(params)

    StripeService.new.initiate_transfer!(transfer)

    render json: representer.to_json, status: :created
  end
end
