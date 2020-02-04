FactoryBot.define do
  factory :capitation_fee_payment, class: Payment do
    provider
    amount { details.fetch(:fee_per_member, 10) * details.fetch(:member_count, 10) }
    type { :capitation_fee }
    effective_date { Time.zone.now.to_date.at_beginning_of_month.next_month }
    paid_at { Time.zone.now }
    details {{
      fee_per_member: rand(1000) + 3000,
      member_count: rand(1000) + 2000
    }}
    transfers { build_pair(:transfer) }
  end

  factory :fee_for_service_payment, class: Payment do
    provider
    amount { details.fetch(:total_cost, 10) - details.fetch(:capitation_fee_paid, 0) }
    type { :fee_for_service }
    effective_date { Time.zone.now.to_date.at_beginning_of_month.prev_month }
    paid_at { Time.zone.now }
    transfers { build_pair(:transfer) }
  end
end
