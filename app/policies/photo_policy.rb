# frozen_string_literal: true

class PhotoPolicy < ApplicationPolicy
  def new?
    create?
  end

  def create?
    user.present?
  end

  def update?
    record.user_id == user&.id
  end

  def destroy?
    update?
  end
end
