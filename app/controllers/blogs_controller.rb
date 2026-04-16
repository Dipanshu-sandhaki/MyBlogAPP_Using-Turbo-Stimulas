require "csv"

class BlogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_blog, only: %i[edit update destroy]

  def index
    @blogs = current_user.blogs.order(created_at: :desc)
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
    @blog = current_user.blogs.build(blog_params)

    if @blog.save
      flash.now[:notice] = "Blog created successfully"
    else
      flash.now[:alert] = @blog.errors.full_messages.to_sentence
    end

    respond_to do |format|
      format.turbo_stream
      format.html do
        if @blog.persisted?
          redirect_to blogs_path, notice: "Blog created successfully"
        else
          render :new, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    if @blog.update(blog_params)
      flash.now[:notice] = "Blog updated successfully"
    else
      flash.now[:alert] = @blog.errors.full_messages.to_sentence
    end

    respond_to do |format|
      format.turbo_stream
      format.html do
        if @blog.errors.empty?
          redirect_to blogs_path, notice: "Blog updated successfully."
        else
          render :edit, status: :unprocessable_entity
        end
      end
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

        current_user.blogs.create!(
          title: title,
          body: body
        )

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

    render turbo_stream: [
      *ids.map { |id| turbo_stream.remove("blog_#{id}") },
      turbo_stream.replace("flash", partial: "shared/flash")
    ]
  else
    flash.now[:alert] = "No blogs selected"

    render turbo_stream: turbo_stream.replace(
      "flash",
      partial: "shared/flash"
    )
  end
end

  def destroy
    @blog.destroy

    flash[:notice] = "Blog deleted successfully"

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to blogs_path, notice: "Blog deleted successfully." }
    end
  end

  private

  def set_blog
    @blog = current_user.blogs.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :body)
  end
end