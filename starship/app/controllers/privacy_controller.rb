class PrivacyController < ApplicationController
  skip_before_filter :login_via_ichain, :require_auth
  def ichain_login
    if session[:redirect_to]
      redirect_to session[:redirect_to]
    else
      redirect_to "/"
    end
  end
end
