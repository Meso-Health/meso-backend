require "rails_helper"

RSpec.describe DiagnosesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/diagnoses").to route_to("diagnoses#index")
    end
  end
end
