require "rails_helper"

RSpec.describe LocalFilesystemDriver do
  describe "listing contents" do
    it "list subdirectories of root" do
      base_dir = Dir.mktmpdir
      create_subdir(base_dir, "foo")
      create_file(base_dir, "bar.org", "")

      driver = LocalFilesystemDriver.new(base_dir)

      expect(driver.list_directory("/")).to match_array([{ "kind" => "directory",
                                                           "name" => "foo",
                                                           "path_display" => "/foo",
                                                           "path_lower" => "/foo" },

                                                         { "kind" => "file",
                                                           "name" => "bar.org",
                                                           "path_display" => "/bar.org",
                                                           "path_lower" => "/bar.org" }])
    end

    it "lists subdirectories in nested paths" do
      base_dir = Dir.mktmpdir
      create_subdir(base_dir, "foo/bar")
      create_file(base_dir, "foo/baz.org", "")

      driver = LocalFilesystemDriver.new(base_dir)

      expect(driver.list_directory("/foo")).to match_array([{ "kind" => "directory",
                                                              "name" => "bar",
                                                              "path_display" => "/foo/bar",
                                                              "path_lower" => "/foo/bar" },

                                                            { "kind" => "file",
                                                              "name" => "baz.org",
                                                              "path_display" => "/foo/baz.org",
                                                              "path_lower" => "/foo/baz.org" }])
    end
  end

  describe "displaying file contents" do
    it "displays contents of files in root directory" do
      base_dir = Dir.mktmpdir
      create_file(base_dir, "foo.org", "foobar")

      driver = LocalFilesystemDriver.new(base_dir)
      expect(driver.get_file("/foo.org")).to eq("foobar")
    end

    it "displays file contents for file in root directory" do
      base_dir = Dir.mktmpdir
      create_subdir(base_dir, "foo")
      create_file(base_dir, "foo/bar.org", "foobar")

      driver = LocalFilesystemDriver.new(base_dir)
      expect(driver.get_file("/foo/bar.org")).to eq("foobar")
    end
  end

  def create_subdir(base_dir, relative_path)
    FileUtils.mkdir_p(absolute_path(base_dir, relative_path))
  end

  def create_file(base_dir, relative_path, content)
    File.write(absolute_path(base_dir, relative_path), content)
  end

  def absolute_path(base_dir, relative_path)
    Pathname.new(base_dir).join(relative_path)
  end
end
