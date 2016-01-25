class PhotosController < ApplicationController
  def index
    @photos = Photo.all
  end

  def new
    @photo = Photo.new
  end

  def create
    @photo = Photo.new(photo_params)
    if @photo.save
      flash[:success] = "Photo saved!"
      redirect_to photos_path
    else
      render 'new'
    end
  end

  def show
    @photo = Photo.find_by(:photo_params)
  end

  private

  def photo_params
    params.require(:photo).permit(:image, :title, :image_size)
  end
end