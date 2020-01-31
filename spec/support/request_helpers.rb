module RequestHelpers
  def json
    JSON.parse(response.body)
  end

  def token_auth_header(user = FactoryBot.create(:user), additional_headers: {})
    token, = PaperTrail.without_versioning { AuthenticationService.new.create_token!(user) }
    {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(token)}.merge(additional_headers)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
