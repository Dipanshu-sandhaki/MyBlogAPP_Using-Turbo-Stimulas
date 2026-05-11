require "csv"

class BlogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_blog, only: %i[edit update destroy]

  # GET /my-blogs — shows only saved + published
  def index
    @blogs = current_user.blogs
                         .where(status: %w[saved published])
                         .order(created_at: :desc)
  end

  # GET /drafts
  def drafts
    @page = (params[:page] || 1).to_i
    @per_page = 10
    
    @drafts = current_user.blogs.draft
                          .order(updated_at: :desc)
                          .limit(@per_page)
                          .offset((@page - 1) * @per_page)
                          
    @has_more = current_user.blogs.draft.count > (@page * @per_page)
  end

  def new
    @blog = current_user.blogs.build
  end

  def edit
  end

  def show
    @blog = current_user.blogs.find(params[:id])
  end

  def create
    @blog        = current_user.blogs.build(blog_params)
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
    @blog.status = resolve_status

    if @blog.update(blog_params)
      redirect_after_save
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def bulk_upload
    render partial: "blogs/bulk_upload"
  end

  def bulk_create
    if params[:file].blank?
      redirect_to blogs_path, alert: "Please upload a CSV file" and return
    end

    file = params[:file]
    created_count = 0
    skipped_count = 0

    unless File.extname(file.original_filename).downcase == ".csv"
      redirect_to blogs_path, alert: "Only CSV files are allowed" and return
    end

    begin
      csv = CSV.read(file.path, headers: true)
      required_headers = %w[title body]
      missing_headers = required_headers - csv.headers.map { |h| h.to_s.strip.downcase }

      if missing_headers.any?
        redirect_to blogs_path, alert: "CSV must include title and body columns" and return
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
        redirect_to blogs_path, notice: "#{created_count} blogs uploaded successfully (#{skipped_count} skipped)"
      else
        redirect_to blogs_path, alert: "No valid rows found in CSV"
      end
    rescue => e
      redirect_to blogs_path, alert: "CSV Upload failed: #{e.message}"
    end
  end

  def bulk_delete
  ids = params[:ids]

  if ids.present?
    current_user.blogs.where(id: ids).destroy_all
    flash.now[:notice] = "Blogs deleted successfully"
  else
    flash.now[:alert] = "No blogs selected"
  end

  respond_to do |format|
    format.turbo_stream
  end
end


  def destroy
    @blog.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: my_blogs_path, notice: "Blog deleted successfully.") }
    end
  end

  private

  def set_blog
    @blog = current_user.blogs.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :cover_image, :status)
  end

  # Reads which submit button was pressed and returns the correct status string
  def resolve_status
    case params[:commit]
    when "Publish"    then "published"
    when "Save"       then "saved"
    when "Save Draft" then "draft"
    else "draft"
    end
  end

  # Redirects to the right page with the right message after create/update
  def redirect_after_save
    case @blog.status
    when "published"
      redirect_to root_path,     notice: "Blog published to feed! 🎉"
    when "saved"
      redirect_to my_blogs_path, notice: "Blog saved to My Blogs."
    when "draft"
      redirect_to drafts_path,   notice: "Draft saved successfully."
    end
  end
end