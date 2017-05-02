class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :check_authenticated

  def app
  end

  def check_authenticated
    unless session[:oauth_token]
      redirect_to "/oauth/auth"
    end
  end
end
