# frozen_string_literal: true

Rails.application.routes.draw do
  # Home page
  root "home#index"

  # Members
  resources :members

  # Teams
  resources :teams

  # Settings
  resource :settings, only: [:show] do
    post :refresh
  end

  # API routes
  namespace :api do
    # OAuth authentication
    scope :auth, as: :auth do
      get :status, to: "auth#status"
      get :connect, to: "auth#connect"
      get :callback, to: "auth#callback"
      delete :disconnect, to: "auth#disconnect"
      post :refresh, to: "auth#refresh"
    end

    # Factory reset
    post :reset, to: "reset#create"

    # Member sync
    resources :members, only: [] do
      collection do
        post :sync
      end
      member do
        post :link
        delete :unlink
      end
    end

    # DoorFlow proxy endpoints
    scope :doorflow, as: :doorflow do
      get :people, to: "doorflow#people"
      get "people/:id", to: "doorflow#person", as: :person
      get :groups, to: "doorflow#groups"
      get :credentials, to: "doorflow#credentials"
      post :credentials, to: "doorflow#create_credential"
      delete "credentials/:id", to: "doorflow#destroy_credential", as: :credential
      put "people/:person_id/groups", to: "doorflow#update_person_groups", as: :update_person_groups
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
