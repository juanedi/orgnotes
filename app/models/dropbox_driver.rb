class DropboxDriver

  def initialize(oauth_token)
    @client = DropboxApi::Client.new(oauth_token)
  end

  def get_file(path)
    @client.download(path) do |content|
      yield content
    end
  end

  def list_directory(path)
    @client
      .list_folder(path)
      .entries
      .map(&:to_hash)
      .select { |r| accept?(r) }
      .map    { |r| api_json(r) }
      .sort_by { |e| sort_key(e) }
  end

  private

  def accept?(api_result)
    api_result[".tag"] == "folder" || api_result["name"] =~ /\.org$/
  end

  def sort_key(entry)
    # list directories first
    [ entry["kind"] == "folder" ? 0 : 1, entry["name"] ]
  end

  def api_json(entry)
    {
      "kind" => entry[".tag"],
      "name" => entry["name"],
      "path_display" => entry["path_display"],
      "path_lower" => entry["path_lower"]
    }
  end
end
