class IChainAuth

  def self.authorize( request_env )
    if request_env.has_key?('HTTP_X_USERNAME')
      authorized_user = Hash.new
      authorized_user['username']  = request_env['HTTP_X_USERNAME']
      authorized_user['email'] = request_env['HTTP_X_EMAIL']
      authorized_user['firstname'] = request_env['HTTP_X_FIRSTNAME'] || ""
      authorized_user['lastname']  = request_env['HTTP_X_LASTNAME'] || ""
      authorized_user['real_name'] = "#{authorized_user['firstname']} #{authorized_user['lastname']}"

      logger.debug("Extracted iChain user: #{authorized_user['username']} (#{authorized_user['email']})")
      return authorized_user
    else
      return nil
    end
  end

  def self.login( return_to_url, host )
    auth_url = "https://" + host + "/ICSLogin/?\"https://" + host + url_for(return_to_url || '/') + "\""
    logger.debug("Redirecting to iChain Login URL #{auth_url}")
    redirect_to( auth_url )
  end

  def self.logout( host )
    redirect_to("https://" + host + "/cmd/ICSLogout/")
  end

  private

  def self.logger
    RAILS_DEFAULT_LOGGER
  end

end
