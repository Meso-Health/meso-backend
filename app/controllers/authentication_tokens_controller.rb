class AuthenticationTokensController < ApplicationController
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  skip_before_action :authenticate_with_token!, only: :create
  before_action :authenticate_with_basic!, only: :create

  def show
    user_json = UserRepresenter.new(@current_user).to_hash
    render json: {expires_at: @current_token.expires_at, user: user_json}
  end

  def create
    combined_token, object = AuthenticationService.new.create_token!(@current_user)
    user_json = UserRepresenter.new(@current_user).to_hash
    json = {token: combined_token, expires_at: object.expires_at, user: user_json}
    render json: json, status: :created
  end

  def destroy
    @current_token.revoke!
    head :no_content
  end

  def current_user
    @current_user
  end

  private
  def authenticate_with_basic!
    authenticate_with_http_basic do |username, password|
      user = User.active.find_by(username: username)
      if user.present? && user.authenticate(password)
        @current_user = user
        PaperTrail.set_whodunnit(@current_user)
      end
    end

    unless @current_user.present?
      request_http_basic_authentication('Identity Provider')
      ExceptionsApp.for(:basic_authentication_incorrect).render(self)
    end
  end
end
