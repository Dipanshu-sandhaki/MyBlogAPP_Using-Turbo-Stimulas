class Users::RegistrationsController < Devise::RegistrationsController

  before_action :configure_account_update_params, only: [:update]

  def edit
    super
  end

  def update
    if params[:user][:remove_avatar] == "1"
      current_user.avatar.purge
    end
    params[:user].delete(:remove_avatar) 
    super
  end

  protected

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:avatar, :remove_avatar])
  end

  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      params.delete(:password)
      params.delete(:password_confirmation)
      params.delete(:current_password)
      resource.update(params)
    else
      resource.update_with_password(params)
    end
  end

  def after_update_path_for(resource)
    root_path
  end
end