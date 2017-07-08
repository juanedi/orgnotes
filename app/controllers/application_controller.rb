class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :check_authenticated

  def app
  end

  def check_authenticated
    unless mock_dropbox? || oauth_token
      redirect_to "/oauth/auth"
    end
  end

  def mock_dropbox?
    ENV['MOCK_DROPBOX']
  end

  def oauth_token
    # session[:oauth_token]
    cookies.encrypted[:orgnotes_data]
  end

  def initialize_driver
    if mock_dropbox?
      LocalFilesystemDriver.new
    else
      DropboxDriver.new(oauth_token)
    end
  end
end
