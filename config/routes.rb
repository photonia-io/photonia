# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :photos do
    resources :taggings, controller: 'photos/taggings'
  end

  resources :tags, only: %i[index show]
  resources :albums, only: %i[index show]

  root 'homepage#index'

  devise_for :users

  # sidekiq
  authenticate :user do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end
end
