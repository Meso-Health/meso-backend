require "rails_helper"

RSpec.describe TransfersController, type: :routing do
  describe "routing" do
    it "routes to #create" do
      expect(post: "/transfers").to route_to("transfers#create")
    end
  end
end
