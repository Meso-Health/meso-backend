# All Administrate controllers inherit from this `Admin::ApplicationController`,
# making it the ideal place to put authentication logic or other
# before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    def current_user
      @current_user
    end

    def logout
      render html: "<div>You are logged out. Click <a href=#{admin_root_path}>here</a> to log in again. </div>".html_safe , status: 401
    end

    before_action :authenticate_admin!

    include ActionController::HttpAuthentication::Basic::ControllerMethods
    def authenticate_admin!
      authenticate_with_http_basic do |username, password|
        user = User.active.find_by(username: username)
        # TODO: Clean this up once we have permissions logic solidified on backend.
        if user.present? && user.authenticate(password) && user.role == 'system_admin'
          @current_user = user
          PaperTrail.set_whodunnit(@current_user)
          PaperTrail.request.controller_info = {
            source: self.class.to_s,
            release_commit_sha: UhpBackend.release.git_sha
          }
        end
      end

      unless @current_user.present?
        request_http_basic_authentication('Identity Provider')
        ExceptionsApp.for(:basic_authentication_incorrect).render(self)
      end
    end
  end
end
