require "rails_helper"

RSpec.describe EncountersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "encounters").to route_to("encounters#index")
    end

    it "routes to #create" do
      expect(post: "/providers/1/encounters").to route_to("encounters#create", provider_id: "1")
    end

    it "routes to #update" do
      expect(patch: "/encounters/8e15204f-1d63-45fb-9e42-af176b0f4fde").to route_to("encounters#update", id: "8e15204f-1d63-45fb-9e42-af176b0f4fde")
    end
  end
end
