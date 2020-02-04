require "rails_helper"

RSpec.describe PriceSchedulesController, type: :routing do
  describe "routing" do
    it "routes to #create" do
      expect(post: "/providers/1/price_schedules").to route_to("price_schedules#create", provider_id: "1")
    end
  end
end
