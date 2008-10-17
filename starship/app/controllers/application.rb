# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :set_return_to, :login_via_ichain, :require_auth

  $OPERATORS = %w{ oneof regexp special }
  
  def login_via_ichain

    # :ICHAIN_TEST is set in config/environments/development.rb
    if Object.const_defined? :ICHAIN_TEST
      user_name = "termite"
      http_email = "termite@suse.de"
      http_real_name = "Hans Peter Termitenhans"
      logger.debug("iChain debug mode, using static user #{user_name} (#{http_email})")
    else
      user_name  = request.env['HTTP_X_USERNAME']
      http_email = request.env['HTTP_X_EMAIL']
      http_first_name = request.env['HTTP_X_FIRSTNAME'] || ""
      http_last_name  = request.env['HTTP_X_LASTNAME'] || ""
      http_real_name = "#{http_first_name} #{http_last_name}"
      logger.debug("Extracted iChain data: #{user_name} (#{http_email})")
    end  
    
    # FIXME: Get information from api.opensuse.org/person/<user_name> and
    #        update/evaluate our database
    
    if !user_name.nil?
      @loggedin_user = Person.find_or_initialize_by_stringid( user_name )
      @loggedin_user.email = http_email
      @loggedin_user.name = http_real_name
      @loggedin_user.save
      session[:user] = @loggedin_user
    end

  end


  def require_auth
    unless @loggedin_user
      redirect_to(:controller => 'account', :action => 'login')
    end
  end


  def redirect_to_index
    redirect_to :controller => :subscriptions
  end


  def current_user
    session[:user]
  end


  def logged_in?
    current_user.is_a? Person
  end
  
  
  def set_return_to
    session[:return_to] = request.request_uri
  end
  

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '444c9e73283339dd0f004698ba1e3f85'
end
