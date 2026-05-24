class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to root_path, alert: "Access denied." unless can?(:create, Blog)

    @period = params[:period] || 'weekly'
    days_back = case @period
                when 'monthly' then 30
                when 'weekly'  then 7
                when 'daily'   then 1
                else 7
                end

    my_blog_ids  = current_user.blogs.select(:id)
    curr_start   = days_back.days.ago.beginning_of_day
    prev_start   = (days_back * 2).days.ago.beginning_of_day

    @total_blogs    = current_user.blogs.published.count
    @total_likes    = Like.where(blog_id: my_blog_ids).count
    @total_comments = Comment.where(blog_id: my_blog_ids).count
    @total_drafts   = current_user.blogs.draft.count

    @period_likes    = Like.where(blog_id: my_blog_ids, created_at: curr_start..Time.current).count
    @period_comments = Comment.where(blog_id: my_blog_ids, created_at: curr_start..Time.current).count
    @period_blogs    = current_user.blogs.published.where(created_at: curr_start..Time.current).count

    prev_likes    = Like.where(blog_id: my_blog_ids, created_at: prev_start..curr_start).count
    prev_comments = Comment.where(blog_id: my_blog_ids, created_at: prev_start..curr_start).count
    prev_blogs    = current_user.blogs.published.where(created_at: prev_start..curr_start).count

    @likes_delta    = delta_percent(@period_likes, prev_likes)
    @comments_delta = delta_percent(@period_comments, prev_comments)
    @blogs_delta    = delta_percent(@period_blogs, prev_blogs)

    @engagement_rate = @total_blogs > 0 ? ((@total_likes + @total_comments).to_f / @total_blogs).round(1) : 0
    @period_engagement = @period_likes + @period_comments

    date_range        = (days_back.days.ago.to_date..Date.today).to_a
    blogs_in_range    = current_user.blogs.published.where(created_at: curr_start..Time.current).group_by { |b| b.created_at.to_date }
    likes_in_range    = Like.where(blog_id: my_blog_ids, created_at: curr_start..Time.current).group_by { |l| l.created_at.to_date }
    comments_in_range = Comment.where(blog_id: my_blog_ids, created_at: curr_start..Time.current).group_by { |c| c.created_at.to_date }

    @labels        = date_range.map { |d| d.strftime(@period == 'monthly' ? "%b %d" : "%a %d") }
    @likes_data    = date_range.map { |d| likes_in_range[d]&.count    || 0 }
    @comments_data = date_range.map { |d| comments_in_range[d]&.count || 0 }
    @blogs_data    = date_range.map { |d| blogs_in_range[d]&.count    || 0 }

    @has_data_in_period = @blogs_data.any?(&:positive?) || @likes_data.any?(&:positive?) || @comments_data.any?(&:positive?)

    @top_blogs = current_user.blogs.published
                             .left_joins(:likes, :comments)
                             .group('blogs.id')
                             .select('blogs.*, COUNT(DISTINCT likes.id) AS likes_count, COUNT(DISTINCT comments.id) AS comments_count')
                             .order('likes_count DESC, comments_count DESC')
                             .limit(5)
    @best_blog = @top_blogs.first

    begin
      recent_likes    = Like.where(blog_id: my_blog_ids).includes(:user, :blog).order(created_at: :desc).limit(6)
      recent_comments = Comment.where(blog_id: my_blog_ids).includes(:user, :blog).order(created_at: :desc).limit(6)

      @recent_activity = (
        recent_likes.map    { |l| { type: 'like',    user: l.user, blog: l.blog, at: l.created_at } } +
        recent_comments.map { |c| { type: 'comment', user: c.user, blog: c.blog, body: c.body.to_s.truncate(60), at: c.created_at } }
      ).sort_by { |a| a[:at] }.reverse.first(8)
    rescue
      @recent_activity = []
    end


    all_activity     = (likes_in_range.keys + comments_in_range.keys + blogs_in_range.keys)
    @most_active_day = all_activity.tally.max_by { |_, v| v }&.first&.strftime("%A") || "N/A"

    @all_blogs_stats = current_user.blogs.published
                                   .left_joins(:likes, :comments)
                                   .group('blogs.id')
                                   .select('blogs.*, COUNT(DISTINCT likes.id) AS likes_count, COUNT(DISTINCT comments.id) AS comments_count')
                                   .order('likes_count DESC')

    begin
      @total_followers  = current_user.followers.count
      @total_following  = current_user.following.count
      @recent_followers = current_user.followers.order(created_at: :desc).limit(5)
    rescue NoMethodError
      @total_followers  = 0
      @total_following  = 0
      @recent_followers = []
    end
  end

  private

  def delta_percent(current, previous)
    return nil if previous.nil?
    return 100 if previous == 0 && current > 0
    return 0   if previous == 0
    (((current - previous).to_f / previous) * 100).round(0)
  end
end