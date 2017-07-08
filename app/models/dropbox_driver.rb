class DropboxDriver

  def initialize(oauth_token)
    @client = DropboxApi::Client.new(oauth_token)
  end

  def get_file(path)
    @client.download(file_path)
  end

  # [{ kind: 'directory', name: "..", path_display: '/../..', path_lower: '/../..' }, ..., ...]
  def list_directory(path)
    @client
      .list_folder(path)
      .entries
      .map(&:to_hash)
      .select { |e| e[".tag"] == "folder" || e["name"] =~ /\.org$/ }
  end
end
