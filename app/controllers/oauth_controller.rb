class OauthController < ActionController::Base
  protect_from_forgery with: :exception

  # Example call:
  # GET /oauth/auth
  def auth
    url = authenticator.authorize_url :redirect_uri => redirect_uri

    redirect_to url
  end

  # Example call:
  # GET /oauth/auth_callback?code=VofXAX8DO1sAAAAAAAACUKBwkDZyMg1zKT0f_FNONeA
  def callback
    auth_bearer = authenticator.get_token(params[:code], :redirect_uri => redirect_uri)
    token = auth_bearer.token
    session[:oauth_token] = token

    redirect_to "/"
  end

  private

  def authenticator
    client_id = ENV['DROPBOX_CLIENT_ID']
    client_secret = ENV['DROPBOX_CLIENT_SECRET']

    DropboxApi::Authenticator.new(client_id, client_secret)
  end

  def redirect_uri
    ENV['DROPBOX_REDIRECT_URI']
  end
end
