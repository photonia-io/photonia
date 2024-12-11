# frozen_string_literal: true

FactoryBot.define do
  factory :impression do
    association :impressionable, factory: :photo
  end
end
