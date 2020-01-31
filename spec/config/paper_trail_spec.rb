require 'rails_helper'

RSpec.describe 'PaperTrail', versioning: true do
  before do
    PaperTrail.request.controller_info = { release_commit_sha: 'current-release-sha' }
  end

  describe 'methods' do
    describe '#with_whodunnit' do
      let(:another_user) { create(:user) }

      it 'executes a block with the provided actor as the whodunnit' do
        has_block_executed = false

        PaperTrail.with_whodunnit(another_user) do
          expect_whodunnit_to_be(another_user)
          has_block_executed = true
        end

        expect(has_block_executed).to be true
      end

      it 'sets the whodunnit back after the block executes' do
        user = create(:user)
        PaperTrail.set_whodunnit(user)

        PaperTrail.with_whodunnit(another_user) do
          foo = 'bar'
        end

        expect_whodunnit_to_be(user)
      end
    end

    describe '#set_whodunnit' do
      it 'sets whodunnit for change tracking' do
        user = create(:user)
        PaperTrail.set_whodunnit(user)
        expect_whodunnit_to_be(user)
      end
    end

    describe '#whodunnit_format' do
      it 'returns the serialized actor' do
        whodunnit = PaperTrail.whodunnit_format(build_stubbed(:user, id: 1))
        expect(whodunnit).to eq 'User:1'
      end
    end

    describe '#without_versioning' do
      it 'executes the block without versioning enabled' do
        expect do
          PaperTrail.without_versioning do
            User.create!(attributes_for(:user))
          end
        end.to_not change(PaperTrail::Version, :count)
      end

      it 'returns the versioning state to before the call' do
        PaperTrail.enabled = false
        PaperTrail.without_versioning do
          User.create!(attributes_for(:user))
        end

        expect(PaperTrail.enabled?).to be false
      end
    end

    def expect_whodunnit_to_be(user)
      administrative_division = create(:administrative_division)
      expect do
        User.create!(attributes_for(:user, administrative_division: administrative_division))
      end.to change(PaperTrail::Version, :count).by(1)

      version = PaperTrail::Version.last
      expect(version.whodunnit).to eq PaperTrail.whodunnit_format(user)
      version
    end
  end

  describe 'Version' do
    describe '#user' do
      let(:user) { create(:user) }
      let(:version) { PaperTrail::Version.create(whodunnit: PaperTrail.whodunnit_format(user)) }

      it 'returns the whodunnit user instance' do
        expect(version.user).to eq user
      end
    end
  end
end
