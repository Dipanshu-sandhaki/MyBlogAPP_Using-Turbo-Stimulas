class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @blog = Blog.find(params[:blog_id])
    @comment = @blog.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.turbo_stream
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "comment_form_#{@blog.id}",
            partial: "comments/form",
            locals: { blog: @blog, comment: @comment }
          )
        }
      end
    end
  end

  # Edit action
  def update
  @comment = current_user.comments.find(params[:id])
  @blog = @comment.blog

  respond_to do |format|
    if @comment.update(comment_params)
      format.turbo_stream
      format.html { redirect_to @blog }
    else
      format.html { redirect_to @blog }
    end
  end
end

  def destroy
    @comment = current_user.comments.find(params[:id])
    @blog = @comment.blog
    @comment.destroy
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end