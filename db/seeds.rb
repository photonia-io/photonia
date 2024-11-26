# frozen_string_literal: true
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# IMPORTANT:
# Make sure your seeds are idempotent, meaning they can be run multiple times without causing issues.
# This is typically done using `find_or_create_by` or `find_or_initialize_by`.

# Create roles

Role.find_or_create_by(name: 'Registered User', symbol: 'registered_user')
Role.find_or_create_by(name: 'Uploader', symbol: 'uploader')

TaggingSource.find_or_create_by(name: 'Flickr')
TaggingSource.find_or_create_by(name: 'Rekognition')
