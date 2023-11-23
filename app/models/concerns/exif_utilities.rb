module EXIFUtilities
  extend ActiveSupport::Concern

  def exif_ifd0
    exif['ifd0']
  end

  def exif_ifd1
    exif['ifd1']
  end

  def exif_exif
    exif['exif']
  end

  def exif_camera_make
    exif_ifd0['make']
  end

  def exif_camera_model
    exif_ifd0['model']
  end

  def exif_camera_friendly_name
    EXIFCamera.new(exif_camera_make, exif_camera_model).friendly_name
  end
end
