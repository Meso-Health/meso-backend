require 'rails_helper'

RSpec.describe EncounterPoolFilterService, :use_database_rewinder do
  describe 'filtering regions in the pilot pool' do
    context 'with pilot region configured' do
      let!(:region_in_pilot) { create(:administrative_division, level: 'region', code: '01') }
      let!(:pilot_region1) { create(:pilot_region, administrative_division: region_in_pilot) }
      let!(:state_in_region1) { create(:administrative_division, level: 'state', code: '01', parent: region_in_pilot) }
      let!(:county_in_region1) { create(:administrative_division, level: 'county', code: '01', parent: state_in_region1) }

      let!(:region2) { create(:administrative_division, level: 'region', code: '02') }
      let!(:state_in_pilot) { create(:administrative_division, level: 'state', code: '01', parent: region2) }
      let!(:pilot_region2) { create(:pilot_region, administrative_division: state_in_pilot) }

      let!(:region3) { create(:administrative_division, level: 'region', code: '03') }
      let!(:state3) { create(:administrative_division, level: 'state', code: '01', parent: region3) }
      let!(:county_in_pilot) { create(:administrative_division, level: 'county', code: '01', parent: state3) }
      let!(:pilot_region3) { create(:pilot_region, administrative_division: county_in_pilot) }

      let!(:region_outside_pilot) { create(:administrative_division, level: 'region', code: '04') }

      context 'member is outside of pilot' do
        let(:household) { create(:household, administrative_division: region_outside_pilot) }
        let(:member) { create(:member, household: household) }

        context 'encounter is started' do
          let!(:encounter) { create(:encounter, :started, member: member) }

          it 'has no effect' do
            EncounterPoolFilterService.new.filter_by_pool!(encounter)
            encounter.reload

            expect(encounter.started?).to be true
          end
        end

        context 'encounter is pending' do
          let!(:encounter) { create(:encounter, :pending, member: member) }

          it 'marks encounter as external' do
            EncounterPoolFilterService.new.filter_by_pool!(encounter)
            encounter.reload

            expect(encounter.external?).to be true
          end
        end

        context 'encounter is revised' do
          let!(:encounter) { create(:encounter, :revised, member: member) }

          it 'has no effect' do
            EncounterPoolFilterService.new.filter_by_pool!(encounter)
            encounter.reload

            expect(encounter.revised?).to be true
          end
        end
      end

      context 'member is in pilot region' do
        let(:household) { create(:household, administrative_division: region_in_pilot) }
        let(:member) { create(:member, household: household) }

        context 'encounter is started' do
          let!(:encounter) { create(:encounter, :started, member: member) }

          it 'has no effect' do
            EncounterPoolFilterService.new.filter_by_pool!(encounter)
            encounter.reload

            expect(encounter.started?).to be true
          end
        end

        context 'encounter is pending' do
          let!(:encounter) { create(:encounter, :pending, member: member) }

          it 'has no effect' do
            EncounterPoolFilterService.new.filter_by_pool!(encounter)
            encounter.reload

            expect(encounter.pending?).to be true
          end
        end
      end

      context 'member is in state contained in pilot region' do
        let(:household) { create(:household, administrative_division: state_in_region1) }
        let(:member) { create(:member, household: household) }
        let!(:encounter) { create(:encounter, :pending, member: member) }

        it 'has no effect' do
          EncounterPoolFilterService.new.filter_by_pool!(encounter)
          encounter.reload

          expect(encounter.pending?).to be true
        end
      end

      context 'member is in county contained in pilot region' do
        let(:household) { create(:household, administrative_division: county_in_region1) }
        let(:member) { create(:member, household: household) }
        let!(:encounter) { create(:encounter, :pending, member: member) }

        it 'has no effect' do
          EncounterPoolFilterService.new.filter_by_pool!(encounter)
          encounter.reload

          expect(encounter.pending?).to be true
        end
      end

      context 'member is in pilot state' do
        let(:household) { create(:household, administrative_division: state_in_pilot) }
        let(:member) { create(:member, household: household) }
        let!(:encounter) { create(:encounter, :pending, member: member) }

        it 'has no effect' do
          EncounterPoolFilterService.new.filter_by_pool!(encounter)
          encounter.reload

          expect(encounter.pending?).to be true
        end
      end

      context 'member is in pilot county' do
        let(:household) { create(:household, administrative_division: county_in_pilot) }
        let(:member) { create(:member, household: household) }
        let!(:encounter) { create(:encounter, :pending, member: member) }

        it 'has no effect' do
          EncounterPoolFilterService.new.filter_by_pool!(encounter)
          encounter.reload

          expect(encounter.pending?).to be true
        end
      end
    end

    context 'with no pilot configured' do
      let!(:member) { create(:member) }
      let!(:encounter) { create(:encounter, :pending, member: member) }

      it 'has no effect' do
        EncounterPoolFilterService.new.filter_by_pool!(encounter)
        encounter.reload

        expect(encounter.pending?).to be true
      end
    end
  end
end
