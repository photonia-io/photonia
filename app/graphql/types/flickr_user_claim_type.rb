# frozen_string_literal: true

module Types
  # GraphQL Flickr User Claim Type
  class FlickrUserClaimType < Types::BaseObject
    description 'A Flickr User Claim'

    field :id, ID, 'ID of the claim', null: false
    field :user, Types::UserType, 'User who is claiming', null: false
    field :flickr_user, Types::FlickrUserType, 'Flickr user being claimed', null: false
    field :claim_type, String, 'Type of claim (automatic or manual)', null: false
    field :status, String, 'Status of the claim (pending, approved, denied)', null: false
    field :verification_code, String, 'Verification code for automatic claims', null: true
    field :reason, String, 'Reason for manual claims', null: true
    field :verified_at, GraphQL::Types::ISO8601DateTime, 'When the claim was verified', null: true
    field :approved_at, GraphQL::Types::ISO8601DateTime, 'When the claim was approved', null: true
    field :denied_at, GraphQL::Types::ISO8601DateTime, 'When the claim was denied', null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, 'When the claim was created', null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, 'When the claim was updated', null: false
  end
end
