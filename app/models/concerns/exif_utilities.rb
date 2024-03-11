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
    if exif_exists? && exif_camera_make && exif_camera_model
      CameraUtilities.new(exif_camera_make, exif_camera_model).friendly_name
    else
      ''
    end
  end

  def exif_f_number
    exif_exif['fnumber'].to_f if exif_exists? && exif_exif['fnumber']
  end

  def exif_exposure_time
    exif_exif['exposure_time'] if exif_exists? && exif_exif['exposure_time']
  end

  def exif_focal_length
    exif_exif['focal_length'].to_f if exif_exists? && exif_exif['focal_length']
  end

  def exif_iso
    exif_exif['iso_speed_ratings'].to_i if exif_exists? && exif_exif['iso_speed_ratings']
  end
end
