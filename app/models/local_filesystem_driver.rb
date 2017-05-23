class LocalFilesystemDriver

  def initialize(base_path)
    @base_path
  end

  def get_file(path)
    full_path = File.join(@base_path, path)
    File.read(full_path)
  end

  # [{ kind: 'directory', path_display: '/../..', path_lower: '/../..' }, ..., ...]
  def list_directory(path)
    entries = Dir[path].select do |entry|
      File.directory?(entry) || entry.end_with? "org"
    end

    entries.map do |entry|
      kind = File.directory?(entry) ? "directory" : "file"

      full_path = Pathname.new(entry)
      root = Pathname.new(@base_path)

      relative_path = full_path.relative_path_from(root).to_s

      { "kind" => kind, "path_display" => relative_path, "path_lower" => relative_path.to_lower }
    end
  end
end
