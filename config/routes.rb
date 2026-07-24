# frozen_string_literal: true

Rails.application.routes.draw do
  # Home page
  root "home#index"

  # Members
  resources :members

  # Teams
  resources :teams

  # Settings
  resource :settings, only: [ :show ] do
    post :refresh
  end

  # Web embed of the DoorFlow.js host SDK — the canonical example of
  # mounting the member widget in a browser via DoorFlow.mount(...).
  get "elements-demo", to: "elements_demo#show", as: :elements_demo

  # API routes
  namespace :api do
    # OAuth authentication
    scope :auth, as: :auth do
      get :status, to: "auth#status"
      get :connect, to: "auth#connect"
      get :callback, to: "auth#callback"
      delete :disconnect, to: "auth#disconnect"
      post :refresh, to: "auth#refresh"

      # Mock CRM-member login — for native clients (e.g. Swift sample) to
      # sign in as a CrmMember without a full SSO flow. The cookie issued
      # here gates the /api/elements/session call below.
      scope :member, as: :member do
        post :login,  to: "auth_member#login"
        post :logout, to: "auth_member#logout"
        get  :me,     to: "auth_member#me"
      end
    end

    # Mint a DoorFlow Elements session JWT for the currently logged-in
    # CrmMember. The widget shell loads /elements/member?token=<jwt> on
    # the DoorFlow host with this token.
    scope :elements, as: :elements do
      post :session, to: "elements#session"
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
