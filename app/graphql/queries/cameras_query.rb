# frozen_string_literal: true

module Queries
  # Cameras (make/model) used by photos visible to the current user, with
  # counts - option list for the advanced search's camera filter (#1101)
  class CamerasQuery < BaseQuery
    description 'List cameras (make/model) used by visible photos, most used first'

    type [Types::CameraType], null: false

    MAX_LIMIT = 100

    Camera = Struct.new(:make, :model, :count) do
      def friendly_name
        CameraUtilities.new(make, model).friendly_name
      end
    end

    def resolve
      base = Pundit.policy_scope(current_user, Photo.unscoped)

      rows = base
             .where("exif #>> '{ifd0,make}' IS NOT NULL AND exif #>> '{ifd0,model}' IS NOT NULL")
             .group(Arel.sql("exif #>> '{ifd0,make}'"), Arel.sql("exif #>> '{ifd0,model}'"))
             .order(Arel.sql('count_all DESC'))
             .limit(MAX_LIMIT)
             .count

      rows.map { |(make, model), count| Camera.new(make, model, count) }
    end
  end
end
