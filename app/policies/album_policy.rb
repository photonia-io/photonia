# frozen_string_literal: true

class AlbumPolicy < ApplicationPolicy
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
