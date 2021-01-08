Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
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
