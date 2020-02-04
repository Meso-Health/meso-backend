require "rails_helper"

RSpec.describe ProviderReportingStatsController, type: :routing do
  describe "routing" do
    it "routes to #show" do
      expect(get: "/provider_reporting_stats/1/").to route_to("provider_reporting_stats#show", provider_id: "1")
    end
  end
end
