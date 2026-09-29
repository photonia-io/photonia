# frozen_string_literal: true

module Types
  # A photo's privacy level, for the advanced search's privacy filter
  # (admin-only in the UI; Pundit still scopes what the query can return).
  class PhotoPrivacy < Types::BaseEnum
    description "A photo's privacy level"

    value 'PUBLIC', 'Public', value: 'public'
    value 'PRIVATE', 'Private', value: 'private'
    value 'FRIENDS_AND_FAMILY', 'Friends & Family', value: 'friends_and_family'
  end
end
