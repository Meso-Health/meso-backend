require "rails_helper"

RSpec.describe HouseholdEnrollmentRecordsController, type: :routing do
  describe "routing" do
    it "routes to #create" do
      expect(post: "/household_enrollment_records").to route_to("household_enrollment_records#create")
    end
  end
end
