class ApiController < ApplicationController

  def list
    driver = initialize_driver
    resource_type = request.headers['HTTP_ORGNOTES_ENTRY_TYPE'] || driver.resource_type(file_path)

    case resource_type
    when Entry::FILE
      driver.get_file(file_path) do |content|
        render json: {
                 type: "note",
                 path: file_path,
                 content: content
               }
      end
    when Entry::DIRECTORY
      render json: {
               type: "directory",
               path: file_path,
               entries: driver.list_directory(file_path)
             }
    else
      head :bad_request
    end
  end

  def file_path
    if params[:path]
      path = "/#{params[:path]}"
    else
      # TODO: may need to fix this for dropbox driver
      path = "/"
    end

    if params[:format]
      path = "#{path}.#{params[:format]}"
    end

    path
  end
end
