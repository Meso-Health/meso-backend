require 'io/console'

namespace :db do
  desc 'Print summary of relevant claim info in DB'
  task print_claims_summary: :environment do
    include ActionView::Helpers::NumberHelper

    def count_and_sum(encounters)
      encounters_sum = encounters.map(&:reimbursal_amount).sum
      "#{encounters.count} | #{number_to_currency(encounters_sum / 100.0)}"
    end

    encounters_with_stockouts = Encounter.joins(:encounter_items).where(encounter_items: { stockout: true }).distinct
    puts "\n\nEncounters with stockouts (#{encounters_with_stockouts.count}):"
    puts encounters_with_stockouts.pluck(:id).join("\n")

    encounters_with_referrals = Encounter.joins(:referrals).distinct
    puts "\nEncounters with referrals (#{encounters_with_referrals.count}):"
    puts encounters_with_referrals.pluck(:id).join("\n")

    encounters_with_stockouts_and_referrals = Encounter.joins(:encounter_items).joins(:referrals).where(encounter_items: { stockout: true }).distinct
    puts "\nEncounters with stockouts and referrals (#{encounters_with_stockouts_and_referrals.count}):"
    puts encounters_with_stockouts_and_referrals.pluck(:id).join("\n")

    encounters_with_inbound_referrals = Encounter.where.not(inbound_referral_date: nil)
    linkable = encounters_with_inbound_referrals.select do |e|
      Referral.includes(:encounter).where(date: e.inbound_referral_date).where(encounters: {member_id: e.member_id}).exists?
    end
    unlinkable = encounters_with_inbound_referrals - linkable
    puts "\nEncounters with inbound referrals (linkable) (#{linkable.count}):"
    puts linkable.pluck(:id).join("\n")
    puts "\nEncounters with inbound referrals (unlinkable) (#{unlinkable.count}):"
    puts unlinkable.pluck(:id).join("\n")

    encounters_with_custom_reimbursal_amounts = Encounter.where.not(custom_reimbursal_amount: nil)
    puts "\nEncounters with custom reimbursal amounts (#{encounters_with_custom_reimbursal_amounts.count}):"
    puts encounters_with_custom_reimbursal_amounts.pluck(:id).join("\n")

    puts '---------------------------------------------------------------------------'
    pending = Encounter.pending
    returned = Encounter.returned
    rejected = Encounter.rejected
    approved = Encounter.approved
    approved_not_reimbursed = approved.where(reimbursement_id: nil)
    approved_reimbursed = approved.where.not(reimbursement_id: nil)
    # should be equal to pending + returned + approved_not_reimbursed
    liable = Encounter.where(reimbursement_id: nil, adjudication_state: ['pending', 'returned', 'approved'])

    puts 'All Providers'
    puts "pending: #{count_and_sum(pending)}"
    puts "returned: #{count_and_sum(returned)}"
    puts "rejected: #{count_and_sum(rejected)}"
    puts "approved (total): #{count_and_sum(approved)}"
    puts "approved (not reimbursed): #{count_and_sum(approved_not_reimbursed)}"
    puts "approved (reimbursed): #{count_and_sum(approved_reimbursed)}"
    puts "total claims liable: #{count_and_sum(liable)}"
    puts "total claims: #{Encounter.pluck(:claim_id).uniq.count}"
    puts "total encounters: #{Encounter.count}"

    Provider.all.each do |p|
      puts "\n#{p.name}"
      puts "pending: #{count_and_sum(pending.where(provider: p))}"
      puts "returned: #{count_and_sum(returned.where(provider: p))}"
      puts "rejected: #{count_and_sum(rejected.where(provider: p))}"
      puts "approved (total): #{count_and_sum(approved.where(provider: p))}"
      puts "approved (not reimbursed): #{count_and_sum(approved_not_reimbursed.where(provider: p))}"
      puts "approved (reimbursed): #{count_and_sum(approved_reimbursed.where(provider: p))}"
      puts "total claims liable: #{count_and_sum(liable.where(provider: p))}"
      puts "total claims: #{Encounter.where(provider: p).pluck(:claim_id).uniq.count}"
      puts "total encounters: #{Encounter.where(provider: p).count}"
    end
  end
end
