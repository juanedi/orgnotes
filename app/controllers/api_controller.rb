class ApiController < ApplicationController

  def list
    #TODO: currently using token from ENV
    client = DropboxApi::Client.new

    if params[:cmd] == "cat"
      client.download(file_path) do |content|
        render plain: content
      end
    else
      entries = client.list_folder(file_path).entries
      render json: entries.map(&:to_hash)
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
end
