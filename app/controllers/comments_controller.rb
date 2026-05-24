class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @blog    = Blog.find(params[:blog_id])
    @comment = @blog.comments.build(comment_params)
    @comment.user = current_user

    authorize! :create, @comment

    if @comment.parent_id.present?
      clicked_comment  = @blog.comments.find_by(id: @comment.parent_id)
      @replied_form_id = clicked_comment&.id
      @comment.parent_id = clicked_comment&.parent_id || clicked_comment&.id
    end

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

  def update
    @comment = current_user.comments.find(params[:id])
    authorize! :update, @comment
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
    authorize! :destroy, @comment
    @blog = @comment.blog
    @comment.destroy

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end
end