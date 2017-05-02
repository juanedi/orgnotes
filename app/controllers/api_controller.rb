class ApiController < ApplicationController

  def list
    client = DropboxApi::Client.new(session[:oauth_token])

    if params[:cmd] == "cat"
      client.download(file_path) do |content|
        render plain: content
      end
    else
      render json: entries(client, file_path)
    end
  end

  def file_path
    if params[:path]
      path = "/#{params[:path]}"
    else
      path = ""
    end

    if params[:format]
      path = "#{path}.#{params[:format]}"
    end

    path
  end

  def entries(client, file_path)
    client
      .list_folder(file_path)
      .entries
      .map(&:to_hash)
      .select { |e| e[".tag"] == "folder" || e["name"] =~ /\.org$/ }
  end
end
