require "rails_helper"

RSpec.describe AuthenticationTokensController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(get: "/authentication_token").to route_to("authentication_tokens#show")
    end

    it "routes to #create" do
      expect(post: "/authentication_token").to route_to("authentication_tokens#create")
    end

    it "routes to #destroy" do
      expect(delete: "/authentication_token").to route_to("authentication_tokens#destroy")
    end
  end
end
