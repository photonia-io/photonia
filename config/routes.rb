# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  post '/graphql', to: 'graphql#execute'
  devise_for :users

  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql' if Rails.env.development?

  resources :photos
  resources :tags, only: %i[index show]
  resources :albums, only: %i[index show]

  root 'homepage#index'

  # sidekiq
  authenticate :user do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end
end
