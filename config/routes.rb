Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'oauth/auth' => 'oauth#auth'
  get 'oauth/callback' => 'oauth#callback'

  scope :api do
    get 'dropbox', to: 'api#list'
    get 'dropbox/*path', to: 'api#list'
  end

  get '/', to: "application#app"
  get '*unmatched_route', :to => 'application#app'

end
