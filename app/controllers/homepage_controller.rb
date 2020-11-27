class HomepageController < ApplicationController
  def index
    @latest_photo = Photo.order(date_taken: :desc).first
    @random_photo = Photo.order(Arel.sql('RANDOM()')).first
  end
end
