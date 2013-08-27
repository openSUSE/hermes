Starship::Application.routes.draw do
  
  #connect '', :controller => 'subscriptions', :action => 'simple'
  root "subscriptions#simple"
  
  resources :messages
  resources :msg_types
  resources :subscriptions do
    post :modify_simple_subscriptions, :on => :collection
  end
 
  get '/feeds/personal', :to => 'feeds#personal'
  get '/feeds', :to => 'feeds#index'
  get '/feeds/:id.:format', :to => 'feeds#show' ##, :constraints => { /[\d,]+/ }
  get '/feeds/:person.:format', :to => 'feeds#person'

  # TODO: add route for named feeds
 
  get '/login', :to => 'account#login'
  get '/logout',  :to => 'account#logout'

  match ':controller(/:action(/:id))(.:format)', :via => [:get, :post] 
end
