class FollowsController < ApplicationController
  before_action :authenticate_user!

  def create
    @user = User.find(params[:id]) 
    unless current_user == @user || current_user.following?(@user)
      current_user.follow!(@user)
    end
    redirect_back fallback_location: root_path
  end

  def destroy
    @user = User.find(params[:id])  
    current_user.unfollow!(@user)
    redirect_back fallback_location: root_path
  end
end