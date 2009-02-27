ActionController::Routing::Routes.draw do |map|
  map.resources :messages
  map.resources :msg_types
 
  map.connect '/subscriptions/simple', :controller => 'subscriptions', :action => 'simple'
  map.resources :subscriptions

  map.connect '/', :controller => 'subscriptions', :action => 'simple'

  map.connect '/login',   :controller => 'account', :action => 'login'
  map.connect '/logout',  :controller => 'account', :action => 'logout'
  
  map.connect '/feeds/:person/:action.:format', :controller => 'feeds'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
end
