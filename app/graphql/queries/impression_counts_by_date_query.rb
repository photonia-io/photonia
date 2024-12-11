# frozen_string_literal: true

module Queries
  # Impressions Query
  class ImpressionCountsByDateQuery < BaseQuery
    description 'Find impression counts by type and date range'

    type [Types::ImpressionType], null: false

    argument :end_date, GraphQL::Types::ISO8601DateTime, 'End date', required: true
    argument :start_date, GraphQL::Types::ISO8601DateTime, 'Start date', required: true
    argument :type, String, 'Type of impression', required: true

    def resolve(type:, start_date:, end_date:)
      context[:authorize].call(Impression, :index?)
      Impression.where(impressionable_type: impressionable_type(type))
                .where(created_at: start_date..end_date)
                .group_by_day(:created_at, range: start_date..end_date, format: '%Y-%m-%d')
                .count
                .map { |date, count| { date: date, count: count } }
    end

    private

    def impressionable_type(type)
      raise GraphQL::ExecutionError, "Invalid impression type: #{type}" unless %w[Photo Tag Album].include?(type)

      type == 'Tag' ? 'ActsAsTaggableOn::Tag' : type
    end
  end
end
