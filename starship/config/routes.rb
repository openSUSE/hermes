ActionController::Routing::Routes.draw do |map|
  
  map.connect '', :controller => 'subscriptions', :action => 'simple'
  
  map.resources :messages
  map.resources :msg_types
  map.resources :subscriptions

  map.connect '/feeds/personal', :controller => 'feeds', :action => 'personal'
  map.connect '/feeds/:id.:format', :controller => 'feeds', :action => 'show', :requirements => { :id => /[\d,]+/ }
  map.connect '/feeds/:person.:format', :controller => 'feeds', :action => 'person'

  # TODO: add route for named feeds
 
  map.connect '/login',   :controller => 'account', :action => 'login'
  map.connect '/logout',  :controller => 'account', :action => 'logout'
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
end
