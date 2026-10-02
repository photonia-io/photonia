# frozen_string_literal: true

module Queries
  class MostViewedOnDateQuery < BaseQuery
    description 'Most viewed photos and albums on a date (admin only)'

    type Types::MostViewedOnDateType, null: false

    argument :date, GraphQL::Types::ISO8601Date, 'Day to look at', required: true
    argument :limit, Integer, 'Max entries per list', required: false, default_value: 10

    def resolve(date:, limit:)
      context[:authorize].call(Impression, :index?)
      range = date.in_time_zone.all_day
      limit = limit.clamp(1, 50)

      { photos: top(Photo, range, limit).map { |r| { photo: r, count: r.views } },
        albums: top(Album, range, limit).map { |r| { album: r, count: r.views } } }
    end

    private

    # unscoped: the admin sees private records too
    def top(model, range, limit)
      model.unscoped
           .joins(:impressions)
           .where(impressions: { created_at: range })
           .group("#{model.table_name}.id")
           .select("#{model.table_name}.*, COUNT(impressions.id) AS views")
           .order(Arel.sql("COUNT(impressions.id) DESC, #{model.table_name}.id DESC"))
           .limit(limit)
    end
  end
end
