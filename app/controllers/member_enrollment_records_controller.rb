class MemberEnrollmentRecordsController < ApplicationController
  def create
    member_enrollment_record = MemberEnrollmentRecord.new
    representer = MemberEnrollmentRecordRepresenter.new(member_enrollment_record)
    representer.from_hash(params)

    member_enrollment_record.save_with_id_collision!

    render json: representer.to_json, status: :created
  end
end