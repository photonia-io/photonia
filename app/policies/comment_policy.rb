# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    return false unless active_user? && commenting_enabled_for?(record.commentable)

    Pundit.policy!(user, record.commentable).show?
  end

  def update?
    active_user? && record.user_id == user.id
  end

  def destroy?
    return false unless active_user?

    user.admin? || record.user_id == user.id || record.commentable.user_id == user.id
  end

  private

  def active_user?
    user.present? && !user.disabled?
  end

  def commenting_enabled_for?(commentable)
    return false unless Setting.commenting_enabled

    commentable.is_a?(Photo) ? Setting.photo_commenting_enabled : Setting.album_commenting_enabled
  end
end
