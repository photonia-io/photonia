# frozen_string_literal: true

namespace :tags do
  desc 'Resets tag tables'
  task reset: :environment do
    ActiveRecord::Base.connection.execute(
      <<~SQL
        TRUNCATE TABLE taggings RESTART IDENTITY CASCADE;
        TRUNCATE TABLE tags RESTART IDENTITY CASCADE;
      SQL
    )
  end
end
