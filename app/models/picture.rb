class Picture < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  mount_uploader :file, PictureUploader

  def to_dropzone_upload
    {
      "id" => id,
      "name" => read_attribute(:file),
      "size" => file.size,
      "delete_url" => picture_path(id: id),
      "delete_type" => "DELETE"
    }
  end
end
