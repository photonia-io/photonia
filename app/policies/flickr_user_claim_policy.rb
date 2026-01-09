# frozen_string_literal: true

class FlickrUserClaimPolicy < ApplicationPolicy
  # Policy scope for Flickr user claims
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      # Admins can see all claims
      return scope.all if user&.admin?

      # Regular users can only see their own claims
      scope.where(user_id: user&.id)
    end
  end

  def index?
    # Only admins can list all claims
    user&.admin? || false
  end

  def show?
    # Admins can see any claim
    return true if user&.admin?

    # Users can see their own claims
    user.present? && record.user_id == user.id
  end

  def create?
    # Any authenticated user can create a claim
    user.present?
  end

  def verify?
    # Users can verify their own pending claims
    user.present? && record.user_id == user.id && record.pending?
  end

  def approve?
    # Only admins can approve claims
    user&.admin? || false
  end

  def deny?
    # Only admins can deny claims
    user&.admin? || false
  end
end
