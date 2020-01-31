require "rails_helper"

RSpec.describe BillablesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/providers/1/billables").to route_to("billables#index", provider_id: "1")
    end
  end
end
