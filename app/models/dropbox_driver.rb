class DropboxDriver

  def initialize(oauth_token)
    @client = DropboxApi::Client.new(oauth_token)
  end

  def resource_type(path)
    # dropbox API doesn't return metadata for the root folder
    return Entry::DIRECTORY if path == "/"

    case @client.get_metadata(path)
    when DropboxApi::Metadata::File
      Entry::FILE
    when DropboxApi::Metadata::Folder
      Entry::DIRECTORY
    end
  end

  def get_file(path)
    @client.download(path) do |content|
      # sometimes a note's contents are wrongly interpreted as being ASCII
      yield content.force_encoding(Encoding::UTF_8)
    end
  end

  def list_directory(path)
    # dropbox API wants "" instead of "/"
    path = "" if path == "/"

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
