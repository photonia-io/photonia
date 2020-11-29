class TagsController < ApplicationController
  include Pagy::Backend

  def show
    @tag = ActsAsTaggableOn::Tag.friendly.find(params[:id])
    @pagy, @photos = pagy(Photo.tagged_with(@tag).order(date_taken: :desc))
  end
end
