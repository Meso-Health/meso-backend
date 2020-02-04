require 'rails_helper'

RSpec.describe "Users", type: :request do
  let!(:current_user) { create(:user, :system_admin) }
  let(:provider) { create(:provider) }
  let(:administrative_division) { create(:administrative_division) }
  let(:readable_user_fields) { %w[id created_at name username role administrative_division_id added_by security_pin adjudication_limit] }
  let(:provider_fields) { %w[provider_id provider_type] }
  describe "GET /users" do
    before do
      create(:user, :payer_admin)
      create(:user, :adjudication)
      create(:user, :enrollment)
      create(:user, :provider_admin, provider: provider)
      create(:user, :identification, provider: provider)
      create(:user, :submission, provider: provider)

      get users_url, headers: token_auth_header(current_user), as: :json
    end

    it 'returns a list of users of a provider' do
      expect(response).to be_successful
      expect(json.size).to eq 7

      system_admin_user = json.find { |u| u['role'] == 'system_admin' }
      expect(system_admin_user.keys).to match_array(readable_user_fields)

      payer_admin_user = json.find { |u| u['role'] == 'payer_admin' }
      expect(payer_admin_user.keys).to match_array(readable_user_fields)

      adjudication_user = json.find { |u| u['role'] == 'adjudication' }
      expect(adjudication_user.keys).to match_array(readable_user_fields)

      enrollment_user = json.find { |u| u['role'] == 'enrollment' }
      expect(enrollment_user.keys).to match_array(readable_user_fields)

      provider_admin_user = json.find { |u| u['role'] == 'provider_admin' }
      expect(provider_admin_user.keys).to match_array(readable_user_fields + provider_fields)

      identification_user = json.find { |u| u['role'] == 'identification' }
      expect(identification_user.keys).to match_array(readable_user_fields + provider_fields)

      submission_user = json.find { |u| u['role'] == 'submission' }
      expect(submission_user.keys).to match_array(readable_user_fields + provider_fields)
    end
  end

  describe "POST /users", use_database_rewinder: true do
    let(:params) do
      {
          name: 'Forrest',
          username: 'forrestgump',
          password: '123456',
          role: 'submission',
          provider_id: provider.id
      }.stringify_keys
    end
    let(:post_request) { post users_url, headers: token_auth_header(current_user), params: params, as: :json }

    context 'current user is a system admin' do
      context 'fields are valid' do
        it 'creates a user' do
          expect{ post_request }.to change { User.count }.by(1)

          expect(response).to have_http_status(201)

          expect(json.keys).to contain_exactly(*(readable_user_fields+provider_fields))
          expect(json.fetch('role')).to eq 'submission'
          applied = %w[name username provider_id]
          expect(json.slice(*applied)).to eq params.slice(*applied)
        end
      end

      context 'fields are missing' do
        let(:params) do
          {
              name: 'Forrest'
          }.stringify_keys
        end

        it 'does not create a user' do
          expect{ post_request }.to change { User.count }.by(0)

          expect(response).to have_http_status(422)

          expect(json['errors'].fetch('username').first).to match(/can't be blank/)
          expect(json['errors'].fetch('password').first).to match(/can't be blank/)
          expect(json['errors'].fetch('role').first).to match(/Role is not included in the list/)
        end
      end

      context 'fields are invalid' do
        let(:params) do
          {
              name: '',
              username: '',
              password: '1234',
              provider_id: provider.id
          }.stringify_keys
        end

        it 'does not create a user' do
          expect{ post_request }.to change { User.count }.by(0)

          expect(response).to have_http_status(422)

          expect(json['errors'].fetch('name').first).to match(/can't be blank/)
          expect(json['errors'].fetch('username').first).to match(/can't be blank/)
          expect(json['errors'].fetch('password').first).to match(/minimum/)
        end
      end
    end

    context 'current user is not a system admin' do
      let!(:current_user) { create(:user, :submission) }

      before do
        post_request
      end

      it 'returns a permission error' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe "PATCH /users/:id" do
    let(:provider_2) { create(:provider) }
    let!(:user) do
      create(:user, :submission,
             name: 'Forrest',
             username: 'forrestgump',
             password: '123456',
             provider_id: provider.id)
    end
    let(:params) do
      {
          name: 'Bubba',
          username: 'bubbagump',
          password: '654321',
          provider_id: provider_2.id
      }.stringify_keys
    end
    let(:patch_request) { patch user_url(user), headers: token_auth_header(current_user), params: params, as: :json }

    context 'current user is a system admin' do
      context 'fields are valid' do
        it 'updates the attributes on the user that are changeable' do
          expect do
            patch_request
            user.reload
          end.
            to change { user.name }.
            and change { user.username }.
            and change { user.password_digest }.
            and not_change { user.provider_id }

          expect(response).to be_successful

          expect(json.keys).to contain_exactly(*(readable_user_fields+provider_fields))
          applied = %w[name username]
          expect(json.slice(*applied)).to eq params.slice(*applied)
        end
      end

      context 'fields are invalid' do
        let(:params) do
          {
              name: '',
              username: '',
              password: '1234',
              provider_id: provider.id
          }
        end

        it 'does not update the attributes' do
          expect do
            patch_request
            user.reload
          end.
            to not_change { user.name }.
            and not_change { user.username }.
            and not_change { user.password_digest }.
            and not_change { user.provider_id }

          expect(response).to have_http_status(422)

          expect(json['errors'].fetch('name').first).to match(/can't be blank/)
          expect(json['errors'].fetch('username').first).to match(/can't be blank/)
          expect(json['errors'].fetch('password').first).to match('Password is too short (minimum is 6 characters)')
        end
      end
    end

    context 'current user is not a system admin' do
      let!(:current_user) { create(:user, :submission) }

      before do
        patch_request
      end

      it 'returns a permission error' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe "DELETE /users/:id" do
    let(:user) { create(:user, :submission) }

    before do
      delete user_url(user), headers: token_auth_header(current_user), as: :json
    end

    context 'current user is a system admin' do
      let!(:current_user) { create(:user, :system_admin) }
      let(:user) { create(:user, :submission) }

      context 'fields are valid' do
        it 'deletes the user' do
          expect(user.reload.deleted?).to eq true
          expect(response).to have_http_status(204)
        end
      end
    end

    context 'current user is not a system admin' do
      let!(:current_user) { create(:user, :submission) }

      it 'returns a permission error' do
        expect(response).to have_http_status(403)
      end
    end
  end
end
