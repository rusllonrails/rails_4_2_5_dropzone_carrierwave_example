class Picture < ActiveRecord::Base
  mount_uploader :file, ImageUploader
end
