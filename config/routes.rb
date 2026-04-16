Rails.application.routes.draw do
  devise_for :users
  root "blogs#index"

  resources :blogs do
    collection do
      get :bulk_upload
      post :bulk_create
      delete :bulk_delete
    end
  end
end