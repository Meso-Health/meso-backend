class UsersController < ApplicationController
  before_action :require_system_admin!

  def index
    users = User.all
    if stale?(users)
      render json: UserRepresenter.for_collection.new(users).to_json
    end
  end

  def create
    user = User.new

    representer = UserRepresenter.new(user)
    representer.from_hash(params)

    user.save!

    render json: representer.to_json, status: :created
  end

  def update
    user = User.find(params[:id])

    representer = UserRepresenter.new(user)
    representer.from_hash(params)
    user.save!

    render json: representer.to_json
  end

  def destroy
    user = User.find(params[:id])
    user.delete!

    head :no_content
  end
end
