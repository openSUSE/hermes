class AccountController < ApplicationController
  skip_before_filter :authenticate, :set_return_to 

  def login
    if ICHAIN_MODE.to_s == 'on' || ICHAIN_MODE.to_s == 'simulate'
      auth_url = "https://mercurius.suse.de/ICSLogin/?\"https://mercurius.suse.de" + url_for(session[:return_to] || '/') + "\""
      redirect_to(auth_url)
    else
      if request.post?
        if session[:user] = Person.authenticate(params[:user][:login], params[:user][:password])
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
      redirect_to("https://mercurius.suse.de/cmd/ICSLogout/")
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
