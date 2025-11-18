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

      # Logged-in users see:
      # - public albums
      # - their own albums (any privacy)
      # - albums shared with them
      shared_album_ids = AlbumShare.where(user_id: user.id).pluck(:album_id)

      scope.where(privacy: 'public')
           .or(scope.where(user_id: user.id))
           .or(scope.where(id: shared_album_ids))
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  ##
  # Check if the user can view a specific album.
  # Returns true if:
  # - Album is public
  # - User owns the album
  # - User is admin
  # - Album is shared with the user (via user_id)
  # - Valid visitor_token is provided in context
  def can_view?
    return true if record.public_privacy?
    return true if user&.admin?
    return true if user && record.user_id == user.id
    return true if user && album_shared_with_user?
    return true if visitor_token_valid?

    false
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

  private

  ##
  # Check if the album is shared with the current user
  def album_shared_with_user?
    return false unless user

    AlbumShare.exists?(album_id: record.id, user_id: user.id)
  end

  ##
  # Check if a valid visitor token is provided for this album
  def visitor_token_valid?
    token = context[:visitor_token]
    return false unless token

    AlbumShare.exists?(album_id: record.id, visitor_token: token)
  end

  ##
  # Access to the context passed from GraphQL
  def context
    @context ||= {}
  end

  ##
  # Allow setting context from outside (e.g., GraphQL resolvers)
  def context=(value)
    @context = value
  end
end
