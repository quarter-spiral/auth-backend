class Admin::UsersController < Admin::ResourcesController
  def update
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      params[:user].delete :password
      params[:user].delete :password_confirmation
    end

    super
  end
end
