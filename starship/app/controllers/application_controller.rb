# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'ichain_auth'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :set_return_to, :authenticate

  $OPERATORS = %w{ oneof containsitem regexp special }
  
  def authenticate
    if ICHAIN_MODE.to_s == 'on' || ICHAIN_MODE.to_s == 'simulate'
      login_via_ichain
    else
      basic_auth
    end
  end

  def basic_auth
    unless session[:userid]
      # We use our own authentication
      if request.env.has_key? 'X-HTTP_AUTHORIZATION'
        # try to get it where mod_rewrite might have put it
        authorization = request.env['X-HTTP_AUTHORIZATION'].to_s.split
      elsif request.env.has_key? 'Authorization'
        # for Apace/mod_fastcgi with -pass-header Authorization
        authorization = request.env['Authorization'].to_s.split
      elsif request.env.has_key? 'HTTP_AUTHORIZATION'
        # this is the regular location
        authorization = request.env['HTTP_AUTHORIZATION'].to_s.split
      end
      logger.debug "authorization: #{authorization}"

      if ( authorization and authorization.size == 2 and
           authorization[0] == "Basic" )
        logger.debug( "AUTH2: #{authorization[1]}" )

        login, passwd = Base64.decode64( authorization[1] ).split(/:/)
        if login and passwd
          @loggedin_user = Person.authenticate login, pass
          if @loggedin_user 
            session[:userid] = @loggedin_user.id
          end
        end
      end
    end

    unless session[:userid]
      # if we still do not have a user in the session it's time to redirect.
      session[:return_to] = request.request_uri
      redirect_to :controller => 'account', :action => 'login'
      return
    end
  end



  def login_via_ichain

    user = Hash.new
    # :ICHAIN_MODE is set in config/environments/development.rb
    if ICHAIN_MODE.to_s == 'simulate'
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
    else
      session[:return_to] = request.request_uri
      redirect_to :controller => 'account', :action => 'login'
      return
    end
  end

  def redirect_to_index
    redirect_to :controller => :subscriptions
  end
  
  
  def set_return_to
    session[:return_to] = request.request_uri
  end
  

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '444c9e73283339dd0f004698ba1e3f85'
end
