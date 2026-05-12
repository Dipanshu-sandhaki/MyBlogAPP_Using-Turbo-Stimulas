class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    
    if @user.update(profile_params)
      @user.avatar.purge if params[:user][:remove_avatar] == '1'
      
      redirect_to root_path, notice: "Profile updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:email, :avatar)
  end
end