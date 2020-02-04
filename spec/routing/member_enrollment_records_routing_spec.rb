require "rails_helper"

RSpec.describe MemberEnrollmentRecordsController, type: :routing do
  describe "routing" do
    it "routes to #create" do
      expect(post: "/member_enrollment_records").to route_to("member_enrollment_records#create")
    end
  end
end
