# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :login_via_ichain, :require_auth, :except => :privacy
  
  def login_via_ichain
    logger.debug('login_via_ichain called!')
    user_name  = request.env['HTTP_X_USERNAME'] || request.env['REMOTE_USER']
    http_email = request.env['HTTP_X_EMAIL']
    http_first_name = request.env['HTTP_X_FIRSTNAME'] || ""
    http_last_name  = request.env['HTTP_X_LASTNAME'] || ""
    http_real_name = "#{http_first_name} #{http_last_name}"
    # extract the email address when we switched to ichain

    # ======================= TEST
    user_name = "termite"
    http_email = "termite@suse.de"

    if user_name
      loggedin_user = Person.find_or_initialize_by_stringid( user_name )
      # FIXME: Get information from api.opensuse.org/person/<user_name> and
      #        update/evaluate our database
      if loggedin_user
        loggedin_user.email = http_email
        if http_real_name 
          loggedin_user.name = http_real_name
        end
        loggedin_user.save
        logger.debug("SAVED new user #{loggedin_user.stringid}")
        
        session[:user] = loggedin_user
      end
    end
  end

  def require_auth
    logger.debug('require_auth called!')
    unless session[:user]
      #render(:text => "Authentication required", :status => 401 ) and return false
      redirect_to(:controller => 'privacy', :action => 'ichain_login' )
    end
  end

  def current_user
    session[:user]
  end

  def logged_in?
    current_user.is_a? Person
  end

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '444c9e73283339dd0f004698ba1e3f85'
end
