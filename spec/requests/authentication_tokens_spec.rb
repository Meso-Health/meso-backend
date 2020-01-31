require 'rails_helper'

RSpec.describe "Authentication Tokens", type: :request do
  let(:readable_user_fields) { %w[id created_at name username role added_by security_pin administrative_division_id adjudication_limit] }
  describe "GET /authentication_token" do
    it 'returns information about the token' do
      get authentication_token_url, headers: token_auth_header, as: :json

      expect(response).to be_successful
      expect(json.keys).to contain_exactly('expires_at', 'user')
      expect(json.fetch('user').keys).to match_array(readable_user_fields)
    end
  end

  describe "POST /authentication_token" do
    it "creates a new authentication token" do
      password = 'password'
      user = create(:user, password: password)
      auth_header = {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user.username, password)}

      post authentication_token_url, headers: auth_header, as: :json

      expect(response).to be_created
      expect(json.keys).to contain_exactly('token', 'expires_at', 'user')
      expect(json.fetch('user').keys).to match_array(readable_user_fields)

      token = AuthenticationToken.last
      expect(token.id).to eq json.fetch('token').split('.').first
      expect(token.user).to eq user
    end
  end

  describe "DELETE /authentication_token" do
    it 'marks the authentication token as revoked' do
      header = token_auth_header
      token_object = AuthenticationToken.last

      delete authentication_token_url, headers: header, as: :json

      expect(response).to be_no_content
      expect(response.body).to be_empty
      expect(token_object.reload).to be_revoked

      get authentication_token_url, headers: header, as: :json
      expect(response).to be_unauthorized
    end
  end
end
