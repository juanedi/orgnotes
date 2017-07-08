class ApiController < ApplicationController

  def list
    driver = initialize_driver

    if params[:cmd] == "cat"
     driver.get_file(file_path) do |content|
        render plain: content
      end
    else
      render json: driver.list_directory(file_path)
    end
  end

  def file_path
    if params[:path]
      path = "/#{params[:path]}"
    else
      path = ""
    end

    if params[:format]
      path = "#{path}.#{params[:format]}"
    end

    path
  end
end
