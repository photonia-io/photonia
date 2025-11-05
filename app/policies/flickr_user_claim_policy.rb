# frozen_string_literal: true

class FlickrUserClaimPolicy < ApplicationPolicy
  def create?
    # Any authenticated user can create a claim
    user.present?
  end

  def verify?
    # Users can verify their own claims
    user.present? && record.user_id == user.id && record.pending?
  end

  def approve?
    # Only admins can approve claims
    user&.admin?
  end

  def deny?
    # Only admins can deny claims
    user&.admin?
  end

  def show?
    # Users can see their own claims, admins can see all
    user&.admin? || (user.present? && record.user_id == user.id)
  end

  def index?
    # Only admins can list all claims
    user&.admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.where(user_id: user&.id)
      end
    end
  end
end
