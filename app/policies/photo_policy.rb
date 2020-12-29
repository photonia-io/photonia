class PhotoPolicy < ApplicationPolicy
  def update?
    record.user_id == user&.id
  end
end
