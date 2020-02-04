module Admin
  class UsersController < Admin::ApplicationController
    # To customize the behavior of this controller,
    # you can overwrite any of the RESTful actions. For example:
    #
    def index
      super
      @resources = User.
        active.
        page(params[:page]).
        per(10)
    end

    def destroy
      user = User.find(params[:id])
      user.delete!
      redirect_to(
        admin_users_path,
        notice: "User #{user.username} successfully de-activated.",
      )
    end

    # Define a custom finder by overriding the `find_resource` method:
    # def find_resource(param)
    #   User.find_by!(slug: param)
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
