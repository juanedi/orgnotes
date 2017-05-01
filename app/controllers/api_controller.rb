class ApiController < ApplicationController

  def list
    #TODO: currently using token from ENV
    client = DropboxApi::Client.new

    if params[:path]
      path = "/#{params[:path]}"
    else
      path = ""
    end

    kind = node_kind(client, path)

    if kind == :folder
      render json: client.list_folder(path).entries.map(&:to_hash)
    else
      client.download(path) do |contents|
        render plain: contents
      end
    end
  end

  def node_kind(client, path)
    if path == ""
      :folder
    else
      metadata = client.get_metadata(path)

      if metadata.is_a? DropboxApi::Metadata::Folder
        :folder
      else
        :file
      end
    end
  end
end
