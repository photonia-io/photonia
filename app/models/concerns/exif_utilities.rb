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
    exif_rational_to_f(exif_exif['fnumber']) if exif_exists? && exif_exif['fnumber']
  end

  def exif_exposure_time
    exif_exif['exposure_time'] if exif_exists? && exif_exif['exposure_time']
  end

  def exif_focal_length
    exif_rational_to_f(exif_exif['focal_length']) if exif_exists? && exif_exif['focal_length']
  end

  def exif_iso
    exif_exif['iso_speed_ratings'].to_i if exif_exists? && exif_exif['iso_speed_ratings']
  end

  private

  # The exif gem serializes rationals (fnumber, focal_length) as "a/b"
  # strings. Plain #to_f on "14/5" gives 14.0, not 2.8, so f/2.8 was
  # displaying as f/14.
  def exif_rational_to_f(value)
    return Rational(value).to_f if value.is_a?(String) && value.match?(%r{\A\d+/\d+\z})

    value.to_f
  end
end
