# frozen_string_literal: true

# job for getting flickr people info
class FlickrPeopleGetInfoJob < ApplicationJob
  queue_as :default

  def perform(flickr_user_id)
    flickr_user = FlickrUser.find_by(id: flickr_user_id)
    response_hash = FlickrAPIService.people_get_info_hash(flickr_user.nsid)
    flickr_user.update(response_hash)
  end
end

