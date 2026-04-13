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
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to blogs_path, notice: "Blog created!" }
    end
  else
    render :new, status: :unprocessable_entity
  end
end

  def update
    if @blog.update(blog_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to blogs_path, notice: "Blog updated successfully." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blog.destroy

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