class LikesController < ApplicationController
  before_action :authenticate_user!

  def create
    @blog = Blog.find(params[:blog_id])
    current_user.likes.create(blog: @blog) unless current_user.liked?(@blog)
    @blog.reload
    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @blog = Blog.find(params[:blog_id])
    current_user.likes.find_by(blog: @blog)&.destroy
    @blog.reload
    respond_to do |format|
      format.turbo_stream
    end
  end
end