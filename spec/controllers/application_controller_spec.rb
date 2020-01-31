require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe "PaperTrail change tracking metadata", versioning: true do
    controller do
      def index
        head :ok
      end
    end

    it 'sets PaperTrail source to the controller action name' do
      get :index

      expect(PaperTrail.request.controller_info[:source]).to eq 'AnonymousController#index'
    end

    it 'sets the PaperTrail release commit sha to the current release' do
      git_sha = 'current-release-sha'
      expect(UhpBackend.release).to receive(:git_sha).and_return(git_sha)

      get :index

      expect(PaperTrail.request.controller_info[:release_commit_sha]).to eq git_sha
    end
  end

  describe "Token authentication" do
    controller do
      before_action :authenticate_with_token!

      def index
        render json: {user_id: @current_user.id, token_id: @current_token.id}
      end
    end

    before do
      request.headers.merge! auth_header
    end

    context 'when a correct combined token is provided' do
      let(:auth_header) {{'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(token)}}
      let(:token) { 'valid.token' }
      let(:token_object) { build_stubbed(:authentication_token, user: user) }
      let(:user) { build_stubbed(:user) }

      before do
        service_double = instance_double('AuthenticationService')
        expect(AuthenticationService).to receive(:new).and_return(service_double)
        expect(service_double).to receive(:verify_token).with(token).and_return(token_object)
        expect(service_double).to_not receive(:token_expired?)
      end

      it 'executes the controller action' do
        get :index

        expect(response).to be_successful
        expect(json.fetch('user_id')).to eq user.id
        expect(json.fetch('token_id')).to eq token_object.id
      end

      it 'sets the whodunnit to the authenticated user' do
        expect(PaperTrail).to receive(:set_whodunnit).with(user)

        get :index
      end

      it 'exposes the authenticated user as #current_user' do
        get :index
        expect(controller.current_user).to eq user
      end
    end

    context 'when incorrect token information is provided' do
      let(:auth_header) {{'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(token)}}
      let(:token) { 'invalid.token' }

      before do
        service_double = instance_double('AuthenticationService')
        expect(AuthenticationService).to receive(:new).and_return(service_double)
        expect(service_double).to receive(:verify_token).with(token).and_return(nil)
        expect(service_double).to receive_messages(token_expired?: false)
      end

      it 'returns an error requesting authentication' do
        get :index

        expect(response).to be_unauthorized
        expect(response.headers).to include('WWW-Authenticate')
        expect(json.fetch('type')).to eq 'token_authentication_incorrect'
      end

      it 'does not expose an authenticated user in #current_user' do
        get :index
        expect(controller.current_user).to be_nil
      end
    end

    context 'when an expired token is provided' do
      let(:auth_header) {{'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(token)}}
      let(:token) { 'expired.token' }
      let(:token_object) { build_stubbed(:authentication_token, user: user) }
      let(:user) { build_stubbed(:user) }

      before do
        service_double = instance_double('AuthenticationService')
        expect(AuthenticationService).to receive(:new).and_return(service_double)
        expect(service_double).to receive(:verify_token).with(token).and_return(nil)
        expect(service_double).to receive(:token_expired?).with(token).and_return(true)
      end

      it 'returns an error requesting authentication' do
        get :index

        expect(response).to be_unauthorized
        expect(response.headers).to include('WWW-Authenticate')
        expect(json.fetch('type')).to eq 'token_authentication_expired'
      end

      it 'does not expose an authenticated user in #current_user' do
        get :index
        expect(controller.current_user).to be_nil
      end
    end

    context 'when no authorization information is provided' do
      let(:auth_header) { {} }

      it 'returns an error requesting authentication' do
        get :index

        expect(response).to be_unauthorized
        expect(response.headers).to include('WWW-Authenticate')
        expect(json.fetch('type')).to eq 'token_authentication_incorrect'
      end

      it 'does not expose an authenticated user in #current_user' do
        get :index
        expect(controller.current_user).to be_nil
      end
    end
  end

  describe 'require_system_admin!' do
    controller do
      skip_before_action :authenticate_with_token!
      before_action :require_system_admin!

      def index
        head :ok
      end
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      get :index
    end

    context 'token is associated with a system admin user' do
      let(:user) { build(:user, :system_admin) }

      it 'executes the controller action' do
        expect(response).to be_ok
      end
    end

    context 'token is not associated with a system admin user' do
      let(:user) { build(:user, :enrollment) }

      it 'returns a forbidden response' do
        expect(response).to be_forbidden
      end
    end
  end
end
