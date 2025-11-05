class FlickrAPIService
  def initialize
    @base_uri = URI('https://api.flickr.com/services/rest')
    @default_params = {
      api_key: ENV['PHOTONIA_FLICKR_API_KEY'],
      format: 'json',
      nojsoncallback: '1'
    }
  end

  def people_get_info(user_id)
    params = @default_params.merge(method: 'flickr.people.getInfo', user_id: user_id)
    @base_uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(@base_uri)
    JSON.parse(response.body)
  end

  def profile_get_profile(user_id)
    params = @default_params.merge(method: 'flickr.profile.getProfile', user_id: user_id)
    @base_uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(@base_uri)
    JSON.parse(response.body)
  end

  # static methods

  def self.people_get_info_hash(user_id)
    response = new.people_get_info(user_id)
    if response['stat'] == 'ok'
      {
        is_deleted: response['person']['is_deleted'] == '1',
        iconserver: response['person']['iconserver'],
        iconfarm: response['person']['iconfarm'],
        username: response.dig('person', 'username', '_content'),
        realname: response.dig('person', 'realname', '_content'),
        location: response.dig('person', 'location', '_content'),
        timezone_label: response.dig('person', 'timezone', 'label'),
        timezone_offset: response.dig('person', 'timezone', 'offset'),
        timezone_id: response.dig('person', 'timezone', 'timezone_id'),
        description: response.dig('person', 'description', '_content'),
        photosurl: response.dig('person', 'photosurl', '_content'),
        profileurl: response.dig('person', 'profileurl', '_content'),
        photos_firstdatetaken: response.dig('person', 'photos', 'firstdatetaken', '_content'),
        photos_firstdate: response.dig('person', 'photos', 'firstdate', '_content'),
        photos_count: response.dig('person', 'photos', 'count', '_content')
      }
    elsif response['stat'] == 'fail' && response['message'] == 'User deleted'
      {
        is_deleted: true
      }
    end
  end

  def self.profile_get_profile_description(user_id)
    response = new.profile_get_profile(user_id)
    if response['stat'] == 'ok'
      response.dig('profile', 'profile_description', '_content')
    end
  end
end
