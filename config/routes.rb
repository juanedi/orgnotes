Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  scope :api do
    get 'dropbox', to: 'api#list'
    get 'dropbox/*path', to: 'api#list'
  end

end
