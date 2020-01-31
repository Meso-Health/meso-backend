class MembershipPaymentsController < ApplicationController
  def create
    membership_payment_record = MembershipPayment.new

    representer = MembershipPaymentRepresenter.new(membership_payment_record)
    representer.from_hash(params)
    membership_payment_record.save_with_id_collision!

    render json: representer.to_json, status: :created
  end
end
