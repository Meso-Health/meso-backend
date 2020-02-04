require 'rails_helper'

RSpec.describe ProviderReportingStatsService do
  let!(:t0) { 20.days.ago }
  let!(:t1) { 18.days.ago }
  let!(:t2) { 16.days.ago }
  let!(:t3) { 14.days.ago }
  let!(:t4) { 12.days.ago }
  let!(:t5) { 10.days.ago }
  let!(:t6) { 8.days.ago }

  let!(:provider) { create(:provider) }
  let!(:another_provider) { create(:provider) }
  let!(:duplicate_encounter) { create(:encounter, identification_event: create(:identification_event, dismissed: true)) }
  let!(:preadjudication_encounter) { create(:encounter, :prepared) }

  let!(:encounter_from_another_provider) { create(:encounter, provider: another_provider)}
  let!(:encounter_out_of_pool) { create(:encounter, :external, provider: provider) }

  # chain size: 1
  let!(:encounterA) { create(:encounter, :approved, provider: provider, submitted_at: t1, custom_reimbursal_amount: 120) }
  let!(:encounterB) { create(:encounter, :rejected, provider: provider, submitted_at: t1, custom_reimbursal_amount: 250) }
  let!(:encounterC) { create(:encounter, :pending, provider: provider, submitted_at: t1, custom_reimbursal_amount: 300) }
  let!(:encounterD) { create(:encounter, :returned, provider: provider, submitted_at: t2, custom_reimbursal_amount: 180) }

  # chain size: 2
  let!(:encounter2) { create(:encounter, :returned, provider: provider, submitted_at: t2, custom_reimbursal_amount: 50) }
  let!(:encounter3) { create(:encounter, :resubmission, provider: provider, submitted_at: t3, revised_encounter: encounter2, custom_reimbursal_amount: 200) }
  # chain size: 3
  let!(:encounter4) { create(:encounter, :returned, provider: provider, submitted_at: t4, custom_reimbursal_amount: 300) }
  let!(:encounter5) { create(:encounter, :resubmission, :returned, provider: provider, submitted_at: t5, revised_encounter: encounter4, custom_reimbursal_amount: 340) }
  let!(:encounter6) { create(:encounter, :resubmission, provider: provider, submitted_at: t6, revised_encounter: encounter5, custom_reimbursal_amount: 180) }

  context 'when there are no start and end dates set' do
    let(:start_date) { nil }
    let(:end_date) { nil }

    it 'returns stats for all of time' do
      service = ProviderReportingStatsService.new(provider.id, start_date, end_date)
      assert_stats_are_all_of_time(service.stats)
    end
  end

  context 'when there is a start date before all the claims' do
    let(:start_date) { t0 - 1.days }
    let(:end_date) { nil }

    it 'returns stats for all of time' do
      service = ProviderReportingStatsService.new(provider.id, start_date, end_date)
      assert_stats_are_all_of_time(service.stats)
    end
  end

  context 'when there is an after all the claims' do
    let(:start_date) { nil }
    let(:end_date) { t6 + 5.days }

    it 'returns stats for all of time' do
      service = ProviderReportingStatsService.new(provider.id, start_date, end_date)
      assert_stats_are_all_of_time(service.stats)
    end
  end

  context 'when start_date and end_date cover all the claims' do
    let(:start_date) { t0 - 1.days }
    let(:end_date) { t4 + 1.days }

    it 'returns stats for all of time' do
      service = ProviderReportingStatsService.new(provider.id, start_date, end_date)
      assert_stats_are_all_of_time(service.stats)
    end
  end

  context 'when start_date cover part of all the claims' do
    let(:start_date) { t2 - 1.days }
    let(:end_date) { nil }

    it 'returns the correct stats' do
      service = ProviderReportingStatsService.new(provider.id, start_date, end_date)
      expect(service.stats).to eq (
        {
          approved: {
            claims_count: 0,
            total_price: 0
          },
          rejected: {
            claims_count: 0,
            total_price: 0
          },
          returned: {
            claims_count: 1, 
            total_price: encounterD.reimbursal_amount
          },
          pending: {
            claims_count: 2,
            total_price: [encounter3, encounter6].sum(&:reimbursal_amount)
          },
          resubmitted_count: 2,
          total: {
            claims_count: 3, 
            price: [encounterD, encounter3, encounter6].sum(&:reimbursal_amount)
          }
      })
    end
  end

  context 'when end_date cover part of all the claims' do
    let(:start_date) { nil }
    let(:end_date) { t4 - 1.days }

    it 'returns the correct stats' do
      service = ProviderReportingStatsService.new(provider.id, start_date, end_date)
      expect(service.stats).to eq (
        {
          approved: {
            claims_count: 1,
            total_price: encounterA.reimbursal_amount
          },
          rejected: {
            claims_count: 1,
            total_price: encounterB.reimbursal_amount
          },
          returned: {
            claims_count: 1, 
            total_price: encounterD.reimbursal_amount
          },
          pending: {
            claims_count: 2, 
            total_price: [encounter3, encounterC].sum(&:reimbursal_amount)
          },
          resubmitted_count: 1,
          total: {
            claims_count: 5,
            price: [encounterA, encounterB, encounterC, encounterD, encounter3].sum(&:reimbursal_amount)
          }
      })
    end
  end

  def assert_stats_are_all_of_time(stats)
      expect(stats).to eq (
        {
          approved: {
            claims_count: 1,
            total_price: encounterA.reimbursal_amount
          },
          rejected: {
            claims_count: 1,
            total_price: encounterB.reimbursal_amount
          },
          returned: {
            claims_count: 1, 
            total_price: encounterD.reimbursal_amount
          },
          pending: {
            claims_count: 3, 
            total_price: [encounter3, encounter6, encounterC].sum(&:reimbursal_amount)
          },
          resubmitted_count: 2,
          total: {
            claims_count: 6, 
            price: [encounterA, encounterB, encounterC, encounterD, encounter3, encounter6].sum(&:reimbursal_amount)
          }
      })
  end
end