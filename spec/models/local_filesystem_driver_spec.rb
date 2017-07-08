require "rails_helper"

RSpec.describe LocalFilesystemDriver do
  describe "listing contents" do
    it "list subdirectories of root" do
      base_dir = Dir.mktmpdir
      create_subdir(base_dir, "foo")
      create_subdir(base_dir, "bar")

      driver = LocalFilesystemDriver.new(base_dir)

      expect(driver.list_directory("/")).to match_array([{ "kind" => "directory",
                                                           "name" => "foo",
                                                           "path_display" => "/foo",
                                                           "path_lower" => "/foo" },

                                                         { "kind" => "directory",
                                                           "name" => "bar",
                                                           "path_display" => "/bar",
                                                           "path_lower" => "/bar" }])
    end

    it "lists subdirectories in nested paths" do
      base_dir = Dir.mktmpdir
      create_subdir(base_dir, "foo/bar")
      create_subdir(base_dir, "foo/baz")

      driver = LocalFilesystemDriver.new(base_dir)

      expect(driver.list_directory("/foo")).to match_array([{ "kind" => "directory",
                                                              "name" => "bar",
                                                              "path_display" => "/foo/bar",
                                                              "path_lower" => "/foo/bar" },

                                                            { "kind" => "directory",
                                                              "name" => "baz",
                                                              "path_display" => "/foo/baz",
                                                              "path_lower" => "/foo/baz" }])
    end
  end

  def create_subdir(base_dir, relative_path)
    FileUtils.mkdir_p(absolute_path(base_dir, relative_path))
  end

  def absolute_path(base_dir, relative_path)
    Pathname.new(base_dir).join(relative_path)
  end
end
