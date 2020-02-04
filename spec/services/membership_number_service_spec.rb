require 'rails_helper'

RSpec.describe MembershipNumberService, :use_database_rewinder do
  subject { described_class.new }

  describe '#issue_membership_number!' do
    let(:household_enrollment_record) { create(:household_enrollment_record) }
    let(:member) { create(:member, household: household_enrollment_record.household) }
    let(:member_enrollment_record) { create(:member_enrollment_record, member: member) }

    before do
      allow(subject).to receive(:next_membership_number)
      .and_return('ABC123')
      subject.issue_membership_number!(member_enrollment_record)
    end

    it 'assigns the subsequent membership number' do
      expect(member.membership_number).to eq 'ABC123'
    end
  end
end
