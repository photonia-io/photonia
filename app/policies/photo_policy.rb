# frozen_string_literal: true

class PhotoPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    # TODO implement private photos
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
