class UserMailer < ApplicationMailer
  def flickr_claim_approved
    @user = params[:user]
    @flickr_user = params[:flickr_user]
    @claim = params[:claim]
    mail to: @user.email, subject: 'Your Flickr user claim has been approved'
  end

  def flickr_claim_denied
    @user = params[:user]
    @flickr_user = params[:flickr_user]
    mail to: @user.email, subject: 'Your Flickr user claim has been denied'
  end

  def new_comment
    @comment = params[:comment]
    @commentable = @comment.commentable
    @author_name = @comment.user.public_name
    @commentable_kind = @commentable.model_name.human.downcase
    @commentable_title = @commentable.title.presence || 'untitled'
    @url = polymorphic_url(@commentable, highlightComment: @comment.serial_number)
    mail to: @commentable.user.email, subject: "New comment on your #{@commentable_kind}: #{@commentable_title}"
  end

  def comment_reply
    @comment = params[:comment]
    @parent = @comment.parent
    @commentable = @comment.commentable
    @author_name = @comment.user.public_name
    @commentable_kind = @commentable.model_name.human.downcase
    @commentable_title = @commentable.title.presence || 'untitled'
    @url = polymorphic_url(@commentable)
    mail to: @parent.user.email, subject: "New reply to your comment on #{@commentable_title}"
  end
end
