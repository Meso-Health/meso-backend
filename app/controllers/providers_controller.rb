class ProvidersController < ApplicationController
  def index
    providers = Provider.all
    render json: ProviderRepresenter.for_collection.new(providers).to_json
  end
end
