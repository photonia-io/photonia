# Photonia

[![Licensed under the Apache License, Version 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)]([http://www.apache.org/licenses/LICENSE-2.0](https://github.com/photonia-io/photonia/blob/development/LICENSE))

A photo hosting service tailored to my needs.

## Technologies

[<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rails/rails-original-wordmark.svg" width="100"/>](https://rubyonrails.org/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/vuejs/vuejs-original.svg" width="100"/>](https://vuejs.org/) [<img src="https://raw.githubusercontent.com/devicons/devicon/develop/icons/vitejs/vitejs-original.svg" width="100"/>](https://vitejs.dev/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/graphql/graphql-plain.svg" width="100"/>](https://graphql.org/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/amazonwebservices/amazonwebservices-original.svg" width="100"/>](https://aws.amazon.com/)

* The backend is Ruby on Rails with Sidekiq as the job processor
* Frontend is VueJS 3 - Development, testing and bundling is done by ViteJS
* Uses GraphQL for communicating between the front and backend, except the photo upload which is a REST call (for now)

## Features

* The photos are stored on [Amazon S3](https://aws.amazon.com/s3/)
* [Amazon Rekognition](https://aws.amazon.com/rekognition/) is run on each photo
* Thumbnails are based on what Rekognition identifies in the photos
* Imports photos and metadata exported from Flickr

## Setup

    sudo apt install libpq-dev libexif-dev

## Development

    bin/vite
    bin/rails s

## Deployment

1. Draft a new release on the [releases page](https://github.com/photonia-io/photonia/releases)
    - Create a tag with the prefix **release-** and the version, eg: **0.1.3** (resulting tag: **release-0.1.3**)
    - Prefix the release title with the release version, eg: **0.1.3 - An awesome release**
2. Publish the release
3. Go to Jenkins and build the tag
