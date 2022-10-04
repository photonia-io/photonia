# Photonia

A photo hosting service tailored to my needs.

## Technologies

Rails - Vue 3 - GraphQL

## Features

* Importing photos and metadata exported from Flickr
* The photos are stored on Amazon S3
* Amazon Rekognition is run on each photo
* Thumbnails are done based on what Rekognition identifies in the photos

## Setup

    sudo apt install libpq-dev libexif-dev
