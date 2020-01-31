require "rails_helper"

RSpec.describe EnrollmentReportingStatsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/enrollment_reporting_stats").to route_to("enrollment_reporting_stats#index")
    end
  end
end
