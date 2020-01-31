require "rails_helper"

RSpec.describe MembersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/providers/1/members").to route_to("members#index", provider_id: "1")
    end

    it "routes to #create" do
      expect(post: "/members").to route_to("members#create")
    end

    it "routes to #update" do
      expect(patch: "/members/2fcc4e66-2400-4c9a-8425-36b8aa3b429d").to route_to("members#update", id: "2fcc4e66-2400-4c9a-8425-36b8aa3b429d")
    end
  end
end
