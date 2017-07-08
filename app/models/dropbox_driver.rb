class DropboxDriver

  def initialize(oauth_token)
    @client = DropboxApi::Client.new(oauth_token)
  end

  def get_file(path)
    @client.download(file_path)
  end

  def list_directory(path)
    @client
      .list_folder(path)
      .entries
      .map(&:to_hash)
      .select { |e| e[".tag"] == "folder" || e["name"] =~ /\.org$/ }
      .map    { |e| api_json(e) }
  end

  private

  def api_json(entry)
    {
      "kind" => entry[".tag"],
      "name" => entry["name"],
      "path_display" => entry["path_display"],
      "path_lower" => entry["path_lower"]
    }
  end
end
