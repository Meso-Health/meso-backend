require 'rails_helper'

RSpec.describe AuthenticationTokensController, type: :controller do
  describe "POST #create" do
    let(:password) { 'password' }
    let(:user) { create(:user, password: password) }

    before do
      request.headers.merge! auth_header
    end

    shared_examples 'fails to authenticate' do
      it 'returns an error requesting authentication' do
        expect(AuthenticationService).to_not receive(:new)

        post :create

        expect(response).to be_unauthorized
        expect(response.headers).to include('WWW-Authenticate')
        expect(json.fetch('type')).to eq 'basic_authentication_incorrect'
      end

      it 'does not expose an authenticated user in #current_user' do
        post :create

        expect(controller.current_user).to be_nil
      end
    end

    context 'when a correct username and password combination is provided' do
      let(:auth_header) {{'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user.username, password)}}
      let(:combined_token) { 'id.secret' }
      let(:token_object) { build_stubbed(:authentication_token, user: user) }

      context 'when the user is active' do
        before do
          service_double = instance_double('AuthenticationService')
          expect(AuthenticationService).to receive(:new).and_return(service_double)
          expect(service_double).to receive(:create_token!).and_return([combined_token, token_object])
        end

        it 'creates an authentication token for that user' do
          post :create

          expect(response).to be_created
          expect(json.fetch('token')).to eq combined_token
          expect(json.fetch('expires_at')).to be
          expect(json.fetch('user').fetch('id')).to eq user.id
        end

        it 'sets the whodunnit to the authenticated user' do
          expect(PaperTrail).to receive(:set_whodunnit).with(user)

          post :create
        end

        it 'exposes the authenticated user as #current_user' do
          post :create

          expect(controller.current_user).to eq user
        end
      end

      context 'when the user has been deleted' do
        let(:user) { create(:user, :deleted, password: password) }

        it_behaves_like 'fails to authenticate'
      end
    end

    context 'when an incorrect password is provided' do
      let(:auth_header) {{'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user.username, 'wrong password')}}

      it_behaves_like 'fails to authenticate'
    end

    context 'when an incorrect username is provided' do
      let(:auth_header) {{'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('wrong username', password)}}

      it_behaves_like 'fails to authenticate'
    end

    context 'when no username and password is provided' do
      let(:auth_header) { {} }

      it_behaves_like 'fails to authenticate'
    end
  end
end
