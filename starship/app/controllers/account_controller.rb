class AccountController < ApplicationController
  skip_before_filter :require_auth

  def login
    auth_url = "https://hermes.opensuse.org/ICSLogin/?\"https://hermes.opensuse.org" + url_for(session[:return_to] || '/') + "\""
    redirect_to(auth_url)
  end

  def logout
    reset_session
    redirect_to("https://hermes.opensuse.org/cmd/ICSLogout/")
  end
end
