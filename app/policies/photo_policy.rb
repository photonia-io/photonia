# frozen_string_literal: true

class PhotoPolicy < ApplicationPolicy
  # Policy scope for photos
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      # Admins can see all photos (works with unscoped relations)
      return scope.all if user&.admin?

      # Visitors see only public photos
      return scope.where(privacy: 'public') unless user

      # Logged-in users see public photos + their own photos (any privacy)
      scope.where(privacy: 'public').or(scope.where(user_id: user.id))
    end
  end

  def index?
    true
  end

  def show?
    return true if user&.admin?
    return record.privacy_public? unless user

    record.privacy_public? || record.user_id == user.id
  end

  def create?
    user.present? && user.has_role?(:uploader)
  end

  def update?
    user.present? && (user.admin? || record.user_id == user.id)
  end

  def destroy?
    update?
  end
end
