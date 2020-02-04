require "rails_helper"

RSpec.describe UsersController, type: :routing do
  describe "routing" do
    it "routes to #create" do
      expect(post: "/households").to route_to("households#create")
    end
  end
end
