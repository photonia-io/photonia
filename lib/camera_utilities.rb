# frozen_string_literal: true

# Utility class to get friendly name of camera make and model
class CameraUtilities
  def initialize(exif_make, exif_model)
    @exif_make = exif_make
    @exif_model = exif_model
  end

  def friendly_name
    camera_make_model_lookup_table
      .fetch(@exif_make) { report_missing_make(@exif_make) }
      .fetch(@exif_model) { report_missing_model(@exif_make, @exif_model) }
      .fetch('friendly_name', "#{@exif_make} #{@exif_model}")
  end

  private

  def camera_make_model_lookup_table
    @camera_make_model_lookup_table ||= begin
      file = File.read(File.join(File.dirname(__FILE__), 'camera_utilities', 'json', 'camera_info.json'))
      JSON.parse(file)
    end
  end

  def report_missing_make(make)
    Sentry.capture_message("Make: #{make} not found", level: 'warning')
    {}
  end

  def report_missing_model(make, model)
    Sentry.capture_message("Model: #{model} not found for make: #{make}", level: 'warning')
    {}
  end
end
