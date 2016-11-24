class PicturesController < ApplicationController

  def index
  end

  def create
    image = Picture.new(file: params[:file])
    image.save

    render json: image.to_dropzone_upload, status: :ok
  end

  def destroy
    image = Picture.find(params[:id])
    image.destroy

    render json: {}, status: :ok
  end
end
