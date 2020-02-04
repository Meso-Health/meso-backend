require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'Validations' do
    describe 'username' do
      it 'enforces uniqueness' do
        username = 'foo'
        create(:user, username: username)
        user = build(:user, username: username)

        expect do
          user.save!(validate: false)
        end.to raise_error ActiveRecord::RecordNotUnique
      end
    end

    describe 'adjudication_limit' do
      it 'allows some user roles to set adjudication_limit ' do
        roles_for_adjudication = [
          :payer_admin,
          :adjudication,
        ]
        roles_for_adjudication.each do |role|
          user = build(:user, role, adjudication_limit: 5000)
          expect(user).to be_valid
        end
      end

      it 'does not allows some user roles to set adjudication_limit' do
        roles_not_for_adjudication = [
          :system_admin,
          :enrollment,
          :provider_admin,
          :identification,
          :submission,
        ]
        roles_not_for_adjudication.each do |role|
          user = build(:user, role, adjudication_limit: 5000)
          expect(user).to_not be_valid
        end
      end
    end

    describe 'password' do
      it 'requires to be at least 6 characters' do
        expect(build(:user, password: '123456')).to be_valid
        expect(build(:user, password: '12345')).to_not be_valid
        expect(build(:user, password: '1234567')).to be_valid
        expect(build(:user, password: 'abcdef')).to be_valid
        expect(build(:user, password: 'iuefhi34t.34g4-13492r02/g34#4t34g34g')).to be_valid
        expect(build(:user, password: '        ')).to be_valid
        expect(build(:user, password: '')).to_not be_valid
        expect(build(:user, password: nil)).to_not be_valid
      end
    end

    describe 'provider' do
      it 'requires a provider set for provider users' do
        user = build_stubbed(:user, :enrollment, provider: nil)
        expect(user).to be_valid

        user = build_stubbed(:user, :provider_admin, provider: nil)
        expect(user).to_not be_valid
        expect(user.errors[:provider]).to_not be_empty
      end
    end
  end

  describe '#delete!' do
    let(:user) { create(:user) }
    let!(:authentication_tokens) { create_list(:authentication_token, 3, user: user) }

    before do
      user.delete!
    end

    it 'marks the user as deleted' do
      expect(user.deleted?).to be true
    end

    it "revokes the user's authentication tokens" do
      expect(user.authentication_tokens.first.revoked?).to be true
      expect(user.authentication_tokens.second.revoked?).to be true
      expect(user.authentication_tokens.third.revoked?).to be true
    end
  end

  describe '#mrn_key', versioning: true do
    it 'returns the correct mrn_key based on each user role' do
      expect(create(:user, :payer_admin).mrn_key).to be nil
      expect(create(:user, :adjudication).mrn_key).to be nil
      expect(create(:user, :enrollment).mrn_key).to eq 'primary'

      provider_users = [
        create(:user, :provider_admin),
        create(:user, :submission),
        create(:user, :identification),
      ]

      provider_users.each do |provider_user|
        expect(provider_user.mrn_key).to eq provider_user.provider.id.to_s
      end
    end
  end

  describe '#added_by', versioning: true do
    let(:admin_user) { create(:user, :system_admin) }

    before do
      PaperTrail.request.controller_info = {release_commit_sha: 'current-release-sha'}
    end

    it 'returns the user that created the current user record' do
      added_user = nil

      PaperTrail.with_whodunnit(admin_user) do
        added_user = User.create(attributes_for(:user))
      end

      expect(added_user.added_by).to eq admin_user
    end
  end
end
