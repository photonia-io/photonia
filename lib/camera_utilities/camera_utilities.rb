class CameraUtilities
  def initialize(exif_make, exif_model)
    @exif_make = exif_make
    @exif_model = exif_model
  end

  def friendly_name
    camera_make_model_lookup_table.fetch(@exif_make, {}).fetch(@exif_model, "#{@exif_make} #{@exif_model}")
  end

  # define a lookup table for camera make and model which returns a friendly name for the camera
  def camera_make_model_lookup_table
    # load camera_info.json from the json directory
    # return the hash
    @camera_make_model_lookup_table ||= begin
      file = File.read(File.join(File.dirname(__FILE__), 'json', 'camera_info.json'))
      JSON.parse(file)
    end
  end
end
