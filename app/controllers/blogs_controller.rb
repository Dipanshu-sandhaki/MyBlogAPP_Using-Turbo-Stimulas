require "csv"

class BlogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_blog,     only: %i[show edit update destroy]
  before_action :set_any_blog, only: %i[read share_email]

  def index
    authorize! :read, Blog
    @page     = (params[:page] || 1).to_i
    @per_page = 5

    base_query = current_user.blogs.where(status: %w[saved published])

    @blogs = base_query.order(created_at: :desc)
                             .limit(@per_page)
                             .offset((@page - 1) * @per_page)
    @has_more    = base_query.count > (@page * @per_page)
    @all_blog_ids = base_query.pluck(:id)

    respond_to do |format|
      format.html
      format.turbo_stream do
        load_more_html = if @has_more
          next_page = @page + 1
          %(<turbo-frame id="load_more_button">
            <div class="mt-8 flex justify-center pb-4">
              <a href="#{my_blogs_path(page: next_page)}"
                 data-turbo-stream="true"
                 class="inline-flex items-center gap-2 px-8 py-3 rounded-full text-sm font-bold tracking-wide bg-white dark:bg-gray-800 text-gray-900 dark:text-white border-2 border-gray-200 dark:border-gray-700 hover:border-blue-500 hover:text-blue-600 dark:hover:border-blue-400 dark:hover:text-blue-400 shadow-sm hover:shadow-md transition-all duration-200 group">
                <svg class="w-4 h-4 stroke-current group-hover:animate-bounce" fill="none" stroke-width="2.5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path d="M19 9l-7 7-7-7" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                Load More
              </a>
            </div>
          </turbo-frame>)
        else
          %(<div id="load_more_button"></div>)
        end

        render turbo_stream: [
          turbo_stream.append("blogs_list_target", partial: "blogs/blog", collection: @blogs),
          turbo_stream.replace("load_more_button", load_more_html)
        ]
      end
    end
  end

  def drafts
    authorize! :create, Blog
    @page     = (params[:page] || 1).to_i
    @per_page = 5

    @drafts   = current_user.blogs.draft
                             .order(updated_at: :desc)
                             .limit(@per_page)
                             .offset((@page - 1) * @per_page)
    @has_more = current_user.blogs.draft.count > (@page * @per_page)
  end

  def new
    authorize! :create, Blog
    @blog = current_user.blogs.build
  end

  def show
    authorize! :read, @blog
  end

  def read
    authorize! :read, @blog
    @comments = @blog.comments.order(created_at: :desc)
  end

  def edit
    authorize! :update, @blog
  end

  def create
    authorize! :create, Blog
    @blog = current_user.blogs.build(blog_params)

    if ["Discard", "Back"].include?(params[:commit])
      if blog_content_empty?
        redirect_to my_blogs_path, notice: "Discarded empty blog."
      else
        @blog.status = "draft"
        @blog.save(validate: false)
        redirect_to drafts_path, notice: "Your progress was saved to Drafts."
      end
      return
    end

    @blog.status = resolve_status

    respond_to do |format|
      format.html do
        if @blog.save
          redirect_after_save
        else
          render :new, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    authorize! :update, @blog

    if ["Discard", "Back"].include?(params[:commit])
      if blog_content_empty?
        redirect_to my_blogs_path, notice: "Discarded empty changes."
      else
        if @blog.published? || @blog.saved?
          redirect_to my_blogs_path, notice: "Changes discarded."
        else
          @blog.status = "draft"
          @blog.update(blog_params)
          redirect_to drafts_path, notice: "Your progress was saved to Drafts."
        end
      end
      return
    end

    @blog.status = resolve_status

    if @blog.update(blog_params)
      redirect_after_save
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def bulk_upload
    authorize! :bulk_upload, Blog
    render partial: "blogs/bulk_upload"
  end

  def bulk_create
    authorize! :bulk_create, Blog
    if params[:file].blank?
      redirect_to my_blogs_path, alert: "Please upload a CSV file" and return
    end

    file = params[:file]
    created_count = 0
    skipped_count = 0

    unless File.extname(file.original_filename).downcase == ".csv"
      redirect_to my_blogs_path, alert: "Only CSV files are allowed" and return
    end

    begin
      csv = CSV.read(file.path, headers: true)
      required_headers = %w[title body]
      missing_headers  = required_headers - csv.headers.map { |h| h.to_s.strip.downcase }

      if missing_headers.any?
        redirect_to my_blogs_path, alert: "CSV must include title and body columns" and return
      end

      csv.each do |row|
        title = row["title"].to_s.strip
        body  = row["body"].to_s.strip

        if title.blank? || body.blank?
          skipped_count += 1
          next
        end

        blog         = current_user.blogs.build(title: title)
        blog.content = body
        blog.status  = "saved"
        blog.save!
        created_count += 1
      end

      if created_count.positive?
        redirect_to my_blogs_path, notice: "#{created_count} blogs uploaded successfully (#{skipped_count} skipped)"
      else
        redirect_to my_blogs_path, alert: "No valid rows found in CSV"
      end
    rescue => e
      redirect_to my_blogs_path, alert: "CSV Upload failed: #{e.message}"
    end
  end

  def bulk_delete
    authorize! :bulk_delete, Blog
    ids = params[:ids]

    if ids.present?
      current_user.blogs.where(id: ids).destroy_all
      flash[:notice] = "Blogs deleted successfully"
    else
      flash[:alert] = "No blogs selected"
    end

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream
    end
  end

  def destroy
    authorize! :destroy, @blog
    @was_draft = @blog.draft?
    @blog.destroy

    notice_message = @was_draft ? "Draft deleted successfully." : "Blog deleted successfully."

    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = notice_message }
      format.html { redirect_back(fallback_location: my_blogs_path, notice: notice_message) }
    end
  end

  def share_email
    authorize! :share_email, @blog
    recipient_email = params[:recipient_email].to_s.strip

    if recipient_email.match?(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
      ArticleMailer.send_article_notification(recipient_email, @blog).deliver_now
      flash[:notice] = "Article sent to #{recipient_email} successfully!"
    else
      flash[:alert] = "Please enter a valid email address."
    end

    redirect_to read_blog_path(@blog)
  end

  private

  def set_blog
    @blog = current_user.blogs.find(params[:id])
  end

  def set_any_blog
    @blog = Blog.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :cover_image, :status)
  end

  def blog_content_empty?
    title        = blog_params[:title].to_s.strip
    content_text = blog_params[:content].to_s.gsub(/<[^>]*>/, "").gsub("&nbsp;", "").strip
    title.blank? && content_text.blank?
  end

  def resolve_status
    case params[:commit]
    when "Publish"  then "published"
    when "Save"     then @blog.published? ? "published" : "saved"
    else                 @blog.status || "draft"
    end
  end

  def redirect_after_save
    case params[:commit]
    when "Publish"
      redirect_to root_path, notice: "Blog published to feed! ✓"
    when "Save"
      redirect_to my_blogs_path, notice: "Blog saved successfully."
    when "Update Blog"
      redirect_to my_blogs_path, notice: "Blog updated successfully! ✓"
    else
      @blog.draft? ? redirect_to(drafts_path, notice: "Draft saved successfully.") : redirect_to(my_blogs_path, notice: "Blog updated successfully! ✓")
    end
  end
end