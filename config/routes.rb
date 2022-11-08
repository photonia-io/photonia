# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  devise_for :users

  resources :photos
  resources :tags, only: %i[index show]
  resources :albums, only: %i[index show]

  post '/graphql', to: 'graphql#execute'

  root 'homepage#index'

  # sidekiq
  authenticate :user do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end
end
