require "rails_helper"

RSpec.describe LocalFilesystemDriver do
  describe "listing contents" do
    it "list subdirectories of root" do
      base_dir = setup_test_tree({ "foo" => {},
                                   "bar.org" => "" })

      driver = LocalFilesystemDriver.new(base_dir)

      expect(driver.list_directory("")).to eq(driver.list_directory("/"))

      expect(driver.list_directory("")).to match_array([{ "kind" => "directory",
                                                          "name" => "foo",
                                                          "path_display" => "/foo",
                                                          "path_lower" => "/foo" },

                                                        { "kind" => "file",
                                                          "name" => "bar.org",
                                                          "path_display" => "/bar.org",
                                                          "path_lower" => "/bar.org" }])
    end

    it "lists subdirectories in nested paths" do
      base_dir = setup_test_tree({ "foo" =>
                                   { "bar" => {},
                                     "baz.org" => "" }})

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
      base_dir = setup_test_tree({ "foo.org" => "foobar" })

      driver = LocalFilesystemDriver.new(base_dir)
      expect(driver.get_file("/foo.org")).to eq("foobar")
    end

    it "displays file contents for file in root directory" do
      base_dir = setup_test_tree({ "foo" => { "bar.org" => "foobar" }})

      driver = LocalFilesystemDriver.new(base_dir)
      expect(driver.get_file("/foo/bar.org")).to eq("foobar")
    end
  end

  def setup_test_tree(contents)
    base_dir = Dir.mktmpdir
    setup_test_dir(base_dir, contents)
    return base_dir
  end

  def setup_test_dir(current_dir, contents)
    contents.each do |k,v|
      absolute_path = Pathname.new(current_dir).join(k)

      if v.is_a?(Hash)
        FileUtils.mkdir_p(absolute_path)
        setup_test_dir(Pathname.new(current_dir).join(k), v)
      elsif v.is_a?(String)
        File.write(absolute_path, v)
      end
    end
  end
end
