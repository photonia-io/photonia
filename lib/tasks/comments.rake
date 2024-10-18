# frozen_string_literal: true

namespace :comments do
  desc 'Resets comment table'
  task reset: :environment do
    ActiveRecord::Base.connection.execute(
      <<~SQL.squish
        TRUNCATE TABLE comments RESTART IDENTITY CASCADE;
      SQL
    )
  end
end
