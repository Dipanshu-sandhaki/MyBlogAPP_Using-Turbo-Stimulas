class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to root_path, alert: "Access denied." unless can?(:create, Blog)

    @period = params[:period] || 'weekly'
    days_back = case @period
                when 'monthly' then 30
                when 'daily'   then 1
                else 7
                end

    my_blog_ids = current_user.blogs.select(:id)

    curr_start = days_back.days.ago.beginning_of_day
    curr_end   = Time.current
    prev_start = (days_back * 2).days.ago.beginning_of_day
    prev_end   = curr_start

    # ── ALL-TIME TOTALS ───────────────────────────────────────────────────────
    @total_blogs_alltime    = current_user.blogs.published.count
    @total_likes_alltime    = Like.where(blog_id: my_blog_ids).count
    @total_comments_alltime = Comment.where(blog_id: my_blog_ids).count
    @total_drafts           = current_user.blogs.draft.count

    # ── PERIOD COUNTS ─────────────────────────────────────────────────────────
    @period_likes    = Like.where(blog_id: my_blog_ids, created_at: curr_start..curr_end).count
    @period_comments = Comment.where(blog_id: my_blog_ids, created_at: curr_start..curr_end).count
    @period_blogs    = current_user.blogs.published.where(created_at: curr_start..curr_end).count

    prev_likes    = Like.where(blog_id: my_blog_ids, created_at: prev_start..prev_end).count
    prev_comments = Comment.where(blog_id: my_blog_ids, created_at: prev_start..prev_end).count
    prev_blogs    = current_user.blogs.published.where(created_at: prev_start..prev_end).count

    @likes_delta    = delta_percent(@period_likes, prev_likes)
    @comments_delta = delta_percent(@period_comments, prev_comments)
    @blogs_delta    = delta_percent(@period_blogs, prev_blogs)

    @period_engagement = @period_likes + @period_comments
    @engagement_rate   = @total_blogs_alltime > 0 ? ((@total_likes_alltime + @total_comments_alltime).to_f / @total_blogs_alltime).round(1) : 0

    # ── CHART DATA ────────────────────────────────────────────────────────────
    if @period == 'daily'
      hours = (0..23).to_a
      blogs_today    = current_user.blogs.published.where(created_at: Date.today.beginning_of_day..Date.today.end_of_day).group_by { |b| b.created_at.hour }
      likes_today    = Like.where(blog_id: my_blog_ids, created_at: Date.today.beginning_of_day..Date.today.end_of_day).group_by { |l| l.created_at.hour }
      comments_today = Comment.where(blog_id: my_blog_ids, created_at: Date.today.beginning_of_day..Date.today.end_of_day).group_by { |c| c.created_at.hour }

      @labels        = hours.map { |h| "#{h}:00" }
      @likes_data    = hours.map { |h| likes_today[h]&.count    || 0 }
      @comments_data = hours.map { |h| comments_today[h]&.count || 0 }
      @blogs_data    = hours.map { |h| blogs_today[h]&.count    || 0 }
    else
      date_range        = (days_back.days.ago.to_date..Date.today).to_a
      blogs_in_range    = current_user.blogs.published.where(created_at: curr_start..curr_end).group_by { |b| b.created_at.to_date }
      likes_in_range    = Like.where(blog_id: my_blog_ids, created_at: curr_start..curr_end).group_by { |l| l.created_at.to_date }
      comments_in_range = Comment.where(blog_id: my_blog_ids, created_at: curr_start..curr_end).group_by { |c| c.created_at.to_date }

      @labels        = date_range.map { |d| d.strftime(@period == 'monthly' ? "%b %d" : "%a") }
      @likes_data    = date_range.map { |d| likes_in_range[d]&.count    || 0 }
      @comments_data = date_range.map { |d| comments_in_range[d]&.count || 0 }
      @blogs_data    = date_range.map { |d| blogs_in_range[d]&.count    || 0 }
    end

    @has_data_in_period = @blogs_data.any?(&:positive?) || @likes_data.any?(&:positive?) || @comments_data.any?(&:positive?)

    unless @period == 'daily'
      all_activity     = (likes_in_range&.keys || []) + (comments_in_range&.keys || []) + (blogs_in_range&.keys || [])
      @most_active_day = all_activity.tally.max_by { |_, v| v }&.first&.strftime("%A") || nil
    else
      @most_active_day = @has_data_in_period ? Date.today.strftime("%A") : nil
    end

    # ── TOP POSTS ─────────────────────────────────────────────────────────────
    blog_counts = current_user.blogs.published
                              .left_joins(:likes, :comments)
                              .group('blogs.id')
                              .select('blogs.id AS id,
                                       COUNT(DISTINCT likes.id)    AS likes_count,
                                       COUNT(DISTINCT comments.id) AS comments_count')
                              .order('likes_count DESC, comments_count DESC')
                              .limit(5)

    blog_ids_ordered = blog_counts.map(&:id)
    counts_by_id     = blog_counts.each_with_object({}) do |r, h|
      h[r.id] = { likes_count: r.likes_count.to_i, comments_count: r.comments_count.to_i }
    end
    blogs_by_id = Blog.where(id: blog_ids_ordered).index_by(&:id)

    @top_blogs = blog_ids_ordered.map do |id|
      blog = blogs_by_id[id]
      next unless blog
      blog.define_singleton_method(:likes_count)    { counts_by_id[id][:likes_count] }
      blog.define_singleton_method(:comments_count) { counts_by_id[id][:comments_count] }
      blog
    end.compact

    @best_blog = @top_blogs.first

    # ── ACTIVITY: last 24 hours, all event types ──────────────────────────────
    last_24h = 24.hours.ago

    # Likes received on my blogs
    received_likes = Like.where(blog_id: my_blog_ids, created_at: last_24h..)
                         .includes(:user, :blog).order(created_at: :desc).limit(20)

    # Comments received on my blogs
    received_comments = Comment.where(blog_id: my_blog_ids, created_at: last_24h..)
                                .includes(:user, :blog).order(created_at: :desc).limit(20)

    # People who followed me in last 24h
    new_followers = current_user.passive_follows
                                .where(created_at: last_24h..)
                                .includes(:follower).order(created_at: :desc).limit(10)

    # People I followed in last 24h
    my_follows = current_user.active_follows
                             .where(created_at: last_24h..)
                             .includes(:followed).order(created_at: :desc).limit(10)

    # My own blog publications in last 24h
    my_publications = current_user.blogs.published
                                  .where(created_at: last_24h..)
                                  .order(created_at: :desc).limit(10)

    # My own comments (replies) I made in last 24h
    my_comments = current_user.comments
                              .where(created_at: last_24h..)
                              .includes(:blog).order(created_at: :desc).limit(10)

    activity_events = []

    received_likes.each    { |l| activity_events << { type: 'like_received',    user: l.user,     blog: l.blog,    at: l.created_at } }
    received_comments.each { |c| activity_events << { type: 'comment_received', user: c.user,     blog: c.blog,    body: c.body.to_s.truncate(60), at: c.created_at } }
    new_followers.each     { |f| activity_events << { type: 'new_follower',     user: f.follower, blog: nil,       at: f.created_at } }
    my_follows.each        { |f| activity_events << { type: 'i_followed',       user: f.followed, blog: nil,       at: f.created_at } }
    my_publications.each   { |b| activity_events << { type: 'published',        user: current_user, blog: b,       at: b.created_at } }
    my_comments.each       { |c| activity_events << { type: 'i_commented',      user: current_user, blog: c.blog,  body: c.body.to_s.truncate(60), at: c.created_at } }

    @recent_activity = activity_events.sort_by { |a| a[:at] }.reverse.first(20)

    @total_followers = current_user.try(:followers)&.count || 0
    @total_following = current_user.try(:following)&.count || 0
  end

  private

  def delta_percent(current, previous)
    return nil if previous.nil?
    return 100 if previous == 0 && current > 0
    return 0   if previous == 0
    (((current - previous).to_f / previous) * 100).round(0)
  end
end