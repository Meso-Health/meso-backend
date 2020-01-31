require "rails_helper"

RSpec.describe EnrollmentPeriodsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/enrollment_periods").to route_to("enrollment_periods#index")
    end
  end
end
