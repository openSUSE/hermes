
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'ichain_auth'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :set_return_to, :authenticate, :require_auth
  protect_from_forgery with: :exception

  class InvalidHttpMethodError < Exception; end
  $OPERATORS = %w{ oneof containsitem regexp}

  def require_auth
    unless session[:userid]
      session[:return_to] = request.request_uri
      redirect_to :controller => 'account', :action => 'login'
    end
  end

  def authenticate
    session[:userid] = nil
    if ichain_mode?
      login_via_ichain
    else
      basic_auth
    end
  end

  def basic_auth
    authenticate_or_request_with_http_basic("Hermes Starship Login") do |id, password|
      @loggedin_user = Person.authenticate id, password
      if @loggedin_user
        session[:userid] = @loggedin_user.id
      end
    end
  end

  def login_via_ichain
    user = Hash.new
    # AUTHENTICATION is set in config/environments/development.rb
    if AUTHENTICATION.to_s == 'simulate'
      user['username'] = "termite"
      user['email'] = "termite@suse.de"
      user['firstname'] = "Hans Peter"
      user['lastname'] = "Dynamit"
      user['real_name'] = "Hans Peter Dynamit"
      logger.debug("iChain debug mode, using static user #{user['username']} (#{user['email']})")
    else
      user = IChainAuth.authorize(request.env)
    end  
    
    # FIXME: Get information from api.opensuse.org/person/<user_name> and
    #        update/evaluate our database
    
    if !user['username'].nil?
      @loggedin_user = Person.find_or_initialize_by_stringid( user['username'] )
      @loggedin_user.email = user['email']
      @loggedin_user.name = user['realname']
      @loggedin_user.save
      session[:userid] = @loggedin_user.id
    end
  end

  def redirect_to_index
    redirect_to :controller => :subscriptions
  end
  
  
  def set_return_to
    session[:return_to] = request.original_url
  end

  def ichain_mode?
    return AUTHENTICATION.to_s == 'ichain' || AUTHENTICATION.to_s == 'simulate'
  end
end
