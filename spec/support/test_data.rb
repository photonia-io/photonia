module TestData
  module_function

  def image_data
    attacher = Shrine::Attacher.new
    attacher.set(uploaded_image)

    # if you're processing derivatives
    attacher.set_derivatives(
      thumbnail_square: uploaded_image,
      medium: uploaded_image,
      large: uploaded_image,
      extralarge: uploaded_image,
    )

    attacher.data
  end

  def uploaded_image
    file = File.open("spec/support/images/zell-am-see-with-exif.jpg")

    # for performance we skip metadata extraction and assign test metadata
    uploaded_file = Shrine.upload(file, :store, metadata: false)
    uploaded_file.metadata.merge!(
      "size"      => File.size(file.path),
      "mime_type" => "image/jpeg",
      "filename"  => "test.jpg",
    )

    uploaded_file
  end
end
