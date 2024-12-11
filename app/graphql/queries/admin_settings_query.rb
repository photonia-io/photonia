# frozen_string_literal: true

module Queries
  # Admin Settings Query
  class AdminSettingsQuery < BaseQuery
    description 'Admin settings'

    type Types::AdminSettingsType, null: false

    def resolve
      authorize(Setting, :edit?)
    end
  end
end
