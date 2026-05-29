class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html  { redirect_to root_path, alert: "Access denied: #{exception.message}" }
      format.turbo_stream { redirect_to root_path, alert: "Access denied: #{exception.message}" }
      format.json  { render json: { error: exception.message }, status: :forbidden }
    end
  end

  protected

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end
end