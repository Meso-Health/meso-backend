class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include ActionController::MimeResponds # required to get respond_to do |format| working
  before_action :authenticate_with_token!

  def current_user
    @current_user
  end

  def append_info_to_payload(payload)
    super
    payload[:token_id] = @current_token.id if @current_token.present?
    payload[:user_id] = @current_user.id if @current_user.present?
  end

  protected
  def info_for_paper_trail
    {
      source: "#{self.class.name}##{action_name}",
      release_commit_sha: UhpBackend.release.git_sha
    }
  end

  def authenticate_with_token!
    authenticate_with_http_token do |token|
      service = AuthenticationService.new
      token_object = service.verify_token(token)
      if token_object.present?
        @current_token = token_object
        @current_user = token_object.user
        PaperTrail.set_whodunnit(@current_user)
      elsif service.token_expired?(token)
        @token_expired = true
      end
    end

    if @token_expired
      request_http_token_authentication('Application')
      ExceptionsApp.for(:token_authentication_expired).render(self)
    elsif !@current_token.present?
      request_http_token_authentication('Application')
      ExceptionsApp.for(:token_authentication_incorrect).render(self)
    end
  end

  def require_system_admin!
    ExceptionsApp.for(:forbidden).render(self) unless User::SYSTEM_ADMIN_ROLES.include? current_user.role
  end

  def require_reimbursement_permitted_user!
    ExceptionsApp.for(:forbidden).render(self) unless User::REMIBURSEMENT_PERMITTED_ROLES.include? current_user.role
  end
end
