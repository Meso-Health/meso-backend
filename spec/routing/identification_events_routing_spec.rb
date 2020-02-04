require "rails_helper"

RSpec.describe IdentificationEventsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/providers/1/identification_events").to route_to("identification_events#index", provider_id: "1")
    end

    it "routes to #create" do
      expect(post: "/providers/1/identification_events").to route_to("identification_events#create", provider_id: "1")
    end

    it "routes to #update" do
      expect(patch: "/identification_events/6949114b-003f-4f30-bde5-8a2032c69528").to route_to("identification_events#update", id: "6949114b-003f-4f30-bde5-8a2032c69528")
    end
  end
end
