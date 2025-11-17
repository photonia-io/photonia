# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check for load balancers and uptime monitors
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Root route
  root 'homepage#index'

  # GraphQL API endpoint
  post 'graphql', to: 'graphql#execute'

  # Devise authentication (skipping all default routes)
  devise_for :users, skip: :all

  # Facebook Data Deletion Request Callback
  post 'facebook_data_deletion/callback', to: 'facebook_data_deletion#callback'
  get 'facebook_data_deletion/status', to: 'facebook_data_deletion#status'

  # Flickr claim approval/denial via email
  get 'flickr_claims/approve', to: 'flickr_claims#approve', as: :flickr_claim_approve
  get 'flickr_claims/deny', to: 'flickr_claims#deny', as: :flickr_claim_deny

  # User-related routes
  scope 'users', controller: 'users' do
    get 'sign_in', action: :sign_in, as: :users_sign_in
    get 'sign_out', action: :sign_out, as: :users_sign_out
    get 'settings', action: :settings, as: :users_settings
    get 'admin-settings', action: :admin_settings, as: :users_admin_settings
  end

  # Admin area routes
  scope 'admin', controller: 'admin' do
    get '', action: :index, as: :admin
    get 'settings', action: :settings, as: :admin_settings
    get 'users', action: :users, as: :admin_users
    get 'users/:id', action: :show_user, as: :admin_show_user
  end

  # Main resource routes
  resources :photos, except: %i[new] do
    collection do
      get :upload
      get :organizer
      get :deselected
      get :feed, defaults: { format: :xml }
    end
  end

  resources :albums, only: %i[index show] do
    collection do
      get :feed, defaults: { format: :xml }
    end
    get :sort
  end

  resources :tags, only: %i[index show]

  # Statistics
  get 'stats', to: 'stats#index'

  # Static pages
  get 'about', to: 'pages#handler'
  get 'terms-of-service', to: 'pages#handler'
  get 'privacy-policy', to: 'pages#handler'

  # Administrative interfaces - Sidekiq web UI
  require 'sidekiq/web'
  require 'sidekiq-scheduler/web'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV.fetch('PHOTONIA_SIDEKIQ_WEB_USERNAME') &&
      password == ENV.fetch('PHOTONIA_SIDEKIQ_WEB_PASSWORD')
  end

  mount Sidekiq::Web => '/sidekiq'
end
