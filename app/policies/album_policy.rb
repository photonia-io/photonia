# frozen_string_literal: true

# Album policy
class AlbumPolicy < ApplicationPolicy
  # Policy scope for albums
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      # Admins can see all albums (works with unscoped relations)
      return scope.all if user&.admin?

      # Visitors see only public albums
      return scope.where(privacy: 'public') unless user

      # Logged-in users see public albums + their own albums (any privacy)
      scope.where(privacy: 'public').or(scope.where(user_id: user.id))
    end
  end

  def index?
    true
  end

  def show?
    true
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
