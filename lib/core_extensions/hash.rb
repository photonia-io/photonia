module CoreExtensions
  module Hash
    # Traverse a hash recursively and for each String value force encoding to ISO-8859-1
    # This is needed because the exif gem returns strings with ASCII-8BIT encoding
    # And the to_json method will fail if the string contains invalid UTF-8 characters
    def force_encoding_to_iso_8859_1
      each do |k, v|
        if v.is_a?(Hash)
          v.force_encoding_to_iso_8859_1
        elsif v.is_a?(String)
          v.force_encoding('ISO-8859-1')
        end
      end
    end
  end
end
