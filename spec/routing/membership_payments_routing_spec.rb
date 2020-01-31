require "rails_helper"

RSpec.describe MembershipPaymentsController, type: :routing do
  describe "routing" do
    it "routes to #create" do
      expect(post: "/membership_payments").to route_to("membership_payments#create")
    end
  end
end
