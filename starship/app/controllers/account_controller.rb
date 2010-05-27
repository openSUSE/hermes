require 'ichain_auth'

class AccountController < ApplicationController
  skip_before_filter :require_auth, :set_return_to

  def login
    if ichain_mode?
      # IChainAuth.login(session[:return_to],request.host)
      auth_url = "https://" + request.host + "/ICSLogin/?\"https://" + request.host + url_for(session[:return_to] || '/') + "\"" 
      logger.debug("Using iChain url #{auth_url}")
      redirect_to(auth_url)
    else
      if request.post?
        user = Person.authenticate(params[:user][:login], params[:user][:password])
        if user
          session[:userid] = user.id
          flash[:message]  = "Login successful"
          redirect_to_index
        else
          flash[:warning] = "Login unsuccessful"
        end
      end
    end
  end

  def logout
    reset_session
    flash[:message] = 'Logged out'
    if ichain_mode?
      # IChainAuth.logout( host )
      redirect_to("https://" + request.host + "/cmd/ICSLogout/")
    else 
      redirect_to :action => 'login'
    end
  end

  def signup
    if ichain_mode?
      flash[:warning]  = "No user signup for iChain, visit http://www.novell.com"
    else
      @user = Person.new(@params[:user])
      if request.post?  
        if @user.save
          user = Person.authenticate(@user.login, @user.password)
          session[:userid] = user.id
          flash[:message] = "Signup successful"
          redirect_to_index 
        else
          flash[:warning] = "Signup unsuccessful"
        end
      end
    end
  end

  def change_password
    @user = Person.find session[:userid]
    if request.post?
      @user.update_attributes(:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
      if @user.save
        flash[:notice]="Password Changed"
      end
      redirect_to_index
    end
  end

end
