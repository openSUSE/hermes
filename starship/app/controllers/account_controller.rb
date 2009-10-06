require 'ichain_auth'

class AccountController < ApplicationController
  skip_before_filter :authenticate, :set_return_to 

  def login
    if ICHAIN_MODE.to_s == 'on' || ICHAIN_MODE.to_s == 'simulate'
      # IChainAuth.login(session[:return_to],request.host)
      auth_url = "https://" + request.host + "/ICSLogin/?\"https://" + request.host + url_for(session[:return_to] || '/') + "\"" 
      logger.debug("Using iChain url #{auth_url}")
      redirect_to(auth_url)
    else
      if request.post?
        session[:user] = Person.authenticate(params[:user][:login], params[:user][:password])
        if session[:user]
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
    if ICHAIN_MODE.to_s == 'on' || ICHAIN_MODE.to_s == 'simulate'
      # IChainAuth.logout( host )
      redirect_to("https://" + request.host + "/cmd/ICSLogout/")
    else 
      redirect_to :action => 'login'
    end
  end

  def signup
    if ICHAIN_MODE.to_s == 'on' || ICHAIN_MODE.to_s == 'simulate'
      flash[:warning]  = "No user signup for iChain, visit http://www.novell.com"
    else
      @user = Person.new(@params[:user])
      if request.post?  
        if @user.save
          session[:user] = Person.authenticate(@user.login, @user.password)
          flash[:message] = "Signup successful"
          redirect_to_index 
        else
          flash[:warning] = "Signup unsuccessful"
        end
      end
    end
  end

  def change_password
    @user=session[:user]
    if request.post?
      @user.update_attributes(:password=>params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
      if @user.save
        flash[:notice]="Password Changed"
      end
      redirect_to_index
    end
  end

end
