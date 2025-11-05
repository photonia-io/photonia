# frozen_string_literal: true

class FlickrClaimsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:approve, :deny]

  def approve
    claim_id = params[:claim_id]
    token = params[:token]

    result = FlickrUserClaimService.approve_claim_by_token(claim_id, token)

    if result[:success]
      render html: "<h1>Claim Approved</h1><p>The Flickr user claim has been approved successfully. The user has been notified.</p>".html_safe
    else
      render html: "<h1>Error</h1><p>#{result[:error]}</p>".html_safe, status: :unprocessable_entity
    end
  end

  def deny
    claim_id = params[:claim_id]
    token = params[:token]

    result = FlickrUserClaimService.deny_claim_by_token(claim_id, token)

    if result[:success]
      render html: "<h1>Claim Denied</h1><p>The Flickr user claim has been denied. The user has been notified.</p>".html_safe
    else
      render html: "<h1>Error</h1><p>#{result[:error]}</p>".html_safe, status: :unprocessable_entity
    end
  end
end
