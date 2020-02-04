class MembershipNumberService
  # With 8 uppercase alphanumeric characters there are 2.8 trillion possible hashes
  DEFAULT_MEMBERSHIP_NUMBER_LENGTH = 8
  MEMBERSHIP_NUMBER_LENGTH = ENV['MEMBERSHIP_NUMBER_LENGTH']&.to_i.presence || DEFAULT_MEMBERSHIP_NUMBER_LENGTH

  def issue_membership_number!(member_enrollment_record)
    member = member_enrollment_record.member
    household_enrollment_record = member.household.most_recent_enrollment_record

    raise 'Household is not enrolled' if household_enrollment_record.nil?

    # TODO: should lock entire members table
    member.update!(membership_number: next_membership_number)
  end

  # Issue a randomly selected hash
  def next_membership_number
    SecureRandom.alphanumeric(MEMBERSHIP_NUMBER_LENGTH).upcase!
  end
end
