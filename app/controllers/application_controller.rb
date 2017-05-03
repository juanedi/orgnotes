class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :check_authenticated

  def app
  end

  def check_authenticated
    unless oauth_token
      redirect_to "/oauth/auth"
    end
  end

  def oauth_token
    # session[:oauth_token]
    cookies.encrypted[:orgnotes_data]
  end
end
