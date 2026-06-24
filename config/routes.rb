Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  root "home#index"
  get "home/index"
  resources :organizations

  namespace :admin do
    resources :dashboard, only: [ :index ] do
      collection do
        delete :destroy_user
        delete :destroy_event
        delete :destroy_organization
        delete :destroy_enrollment
        patch  :update_user_role
      end
    end
    resources :users, only: %i[new create edit update]
    resources :organizations, only: %i[new create edit update]
    resources :enrollments, only: %i[new create]
    resources :events, only: %i[new create] do
      member do
        get :available_volunteers
      end
    end
  end

  resource :quiz, only: [:show, :update], controller: :quiz do
    member do
      patch :toggle_availability
    end
  end

  resources :notifications, only: [ :index ] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end

  get "/perfil", to: "profiles#show", as: :perfil

  resources :events do
    member do
      patch :iniciar
      patch :finalizar
    end
    resource :reviews, only: [:new, :create], controller: "event_reviews"
    resources :enrollments, only: [ :create, :update, :destroy ] do
      member do
        patch :mark_attendance
      end
    end
    resources :messages, only: [ :create ]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
