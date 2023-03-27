# frozen_string_literal: true

Rails.application.routes.draw do
  get '/users/sign_in', to: 'users#sign_in'
  get '/users/sign_out', to: 'users#sign_out'
  get '/users/settings', to: 'users#settings'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  devise_for :users, skip: :all

  resources :photos, except: %i[new] do
    get :upload, on: :collection
  end
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
