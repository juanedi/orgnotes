class LocalFilesystemDriver

  def initialize(base_path)
    @root_path = Pathname.new(base_path)
  end

  def get_file(path)
    file_path = absolute_path(path)

    raise "not found" unless File.file?(file_path) && File.readable?(file_path)
    contents = File.read(file_path)

    if block_given?
      yield contents
    else
      return contents
    end
  end

  def list_directory(path)
    dir_path = absolute_path(path)

    raise "not found" unless Dir.exists?(dir_path) && File.readable?(dir_path)

    entries = Dir.entries(dir_path).select { |e| !e.starts_with? "." }

    entries.reduce([]) do |result, entry_name|
      entry_absolute_path = Pathname.new(dir_path).join(entry_name).to_s
      entry_relative_path = relative_path(entry_absolute_path)

      if File.directory?(entry_absolute_path)
        result.push(entry_json("directory", entry_name, entry_relative_path))
      elsif entry_name.ends_with? "org"
        result.push(entry_json("file", entry_name, entry_relative_path))
      else
        result
      end
    end
  end

  private

  def entry_json(kind, name, relative_path)
    {
      "kind" => kind,
      "name" => name,
      "path_display" => "/#{relative_path}",
      "path_lower" => "/#{relative_path}".downcase
    }
  end

  def absolute_path(relative_path)
    sanitized = relative_path.gsub(/^\//, "./") # "/" => "./"
    @root_path.join(sanitized)
  end

  def relative_path(absolute_path)
    Pathname.new(absolute_path).relative_path_from(@root_path).to_s
  end
end
