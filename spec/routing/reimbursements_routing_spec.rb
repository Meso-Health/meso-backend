require "rails_helper"

RSpec.describe ReimbursementsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/reimbursements").to route_to("reimbursements#index")
    end

    it "routes to #create" do
      expect(post: "/providers/1/reimbursements").to route_to("reimbursements#create", provider_id: "1")
    end

    it "routes to #update" do
      expect(patch: "/reimbursements/2fcc4e66-2400-4c9a-8425-36b8aa3b429d").to route_to("reimbursements#update", id: "2fcc4e66-2400-4c9a-8425-36b8aa3b429d")
    end

    it "routes to #stats" do
      expect(get: "/reimbursements/stats?provider_id=2").to route_to("reimbursements#stats", provider_id: "2")
    end

    it "routes to #claims" do
      expect(get: "/reimbursements/1/claims").to route_to("reimbursements#claims", reimbursement_id: "1")
    end
  end
end
