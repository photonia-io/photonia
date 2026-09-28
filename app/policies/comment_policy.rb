# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    return false unless active_user? && Setting.commenting_enabled

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
end
