Rails.application.routes.draw do
  namespace :admin do
    resources :administrative_divisions, only: %i(index show new create update edit)
    resources :users, only: %i(index show new create update edit delete destroy)
    resources :providers, only: %i(index show new create update edit) do
      collection do
        get :export
      end
    end
    resources :enrollment_periods, only: %i(index show new create update edit)
    resources :card_batches, only: %i(index show new create) do
      get :export
    end
    resources :billables, only: %i(index show new create update edit) do
      collection do
        get :export
        post :import
      end
    end
    resources :diagnoses_groups, only: %i(index show new create) do
      get :export
      post :import
    end
    resources :price_schedules, only: %i(index show new create) do
      collection do
        get :export
        post :import
      end
    end
    resources :patient_experiences, only: %i(index show new create)
    get 'logout', to: Admin::ApplicationController.action(:logout)
    resources :diagnoses, only: %i(index show new create update edit)
    if ActiveModel::Type::Boolean.new.cast(ENV['ADMIN_PANEL_ENABLE_PILOT_REGIONS'])
      resources :pilot_regions, only: %i(index show new create delete destroy)
    end
    root to: "administrative_divisions#index"
  end

  match '/', to: StatusController.action(:index), via: :get, as: :root
  mount StatusController.action(:index), at: '/status', via: :get, as: :status

  mount Dragonfly.app, at: '/dragonfly', via: :get

  resource :authentication_token, only: [:show, :create, :destroy]
  resources :encounters, only: [:index, :update] # TODO: remove encounters/index endpoint after admin switches to paginated /claims endpoint
  resources :claims, only: [:index, :show], param: :encounter_id, defaults: { format: 'json' }
  resources :enrollment_periods, only: :index
  resources :identification_events, only: :update
  get '/members/:id/claims', to: 'claims#member_claims'
  resources :members, only: [:create, :update] do
    collection do
      get :search, path: 'search'
    end
  end
  resources :reimbursements, only: [:index, :update] do
    get :claims, 'claims'
    collection do
      get :stats, 'stats'
      get :reimbursable_claims_metadata, 'reimbursable_claims_metadata'
    end
  end
  resources :users, only: [:index, :create, :update, :destroy]
  resources :transfers, only: :create
  resources :diagnoses, only: :index
  resources :households, only: :create do
    collection do
      get :search, path: 'search'
    end
  end
  resources :membership_payments, only: :create
  resources :household_enrollment_records, only: [:create, :index]
  resources :member_enrollment_records, only: :create
  resources :administrative_divisions, only: :index

  resources :enrollment_reporting_stats, only: :index
  get '/provider_reporting_stats/:provider_id', to: 'provider_reporting_stats#show'
  get '/reimbursement_reporting/:reimbursement_id/csv/', to: 'reimbursement_reporting#csv'

  resources :providers, only: [:index] do
    resources :price_schedules, only: :create
    resources :members, only: :index
    resources :billables, only: [:index, :create]
    resources :identification_events, only: [:index, :create] do
      collection do
        get 'open'
      end
    end
    resources :reimbursements, only: [:create]
    resources :encounters, only: [:index, :create] do # TODO: remove providers/encounters/index endpoint after admin switches to paginated /claims endpoint
      collection do
        get 'returned'
      end
    end
  end
end
