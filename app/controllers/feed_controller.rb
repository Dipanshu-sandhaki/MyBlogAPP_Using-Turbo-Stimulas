class FeedController < ApplicationController
  before_action :authenticate_user!

  def index
    followed_ids = current_user.following.pluck(:id)
    feed_ids = followed_ids + [current_user.id]

    @blogs = Blog.where(user_id: feed_ids)
                 .includes(:user, :likes, :comments)
                 .order(created_at: :desc)

    @all_users = User.where.not(id: current_user.id)
                     .includes(:avatar_attachment, :blogs)
                     .order(created_at: :desc)
  end
end