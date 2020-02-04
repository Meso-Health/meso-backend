require "rails_helper"

RSpec.describe AdministrativeDivisionsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/administrative_divisions").to route_to("administrative_divisions#index")
    end
  end
end
