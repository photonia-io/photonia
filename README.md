# Photonia

[![Test coverage](https://codecov.io/gh/photonia-io/photonia/graph/badge.svg?token=kLLGDkhYew)](https://codecov.io/gh/photonia-io/photonia)
[![Licensed under the Apache License, Version 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](<[http://www.apache.org/licenses/LICENSE-2.0](https://github.com/photonia-io/photonia/blob/development/LICENSE)>)

A photo hosting service tailored to my needs.

## Technologies

[<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rails/rails-original-wordmark.svg" width="100"/>](https://rubyonrails.org/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/vuejs/vuejs-original.svg" width="100"/>](https://vuejs.org/) [<img src="https://raw.githubusercontent.com/devicons/devicon/develop/icons/vitejs/vitejs-original.svg" width="100"/>](https://vitejs.dev/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/bulma/bulma-plain.svg" width="100"/>](https://bulma.io/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/graphql/graphql-plain.svg" width="100"/>](https://graphql.org/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/amazonwebservices/amazonwebservices-plain-wordmark.svg" width="100"/>](https://aws.amazon.com/)

- The backend is Ruby on Rails with Sidekiq as the job processor
- Frontend is VueJS 3 - Development, testing and bundling is done by ViteJS
- Uses GraphQL for communicating between the front and backend, except the photo upload which is a REST call (for now)

## Features

- The photos are stored on [Amazon S3](https://aws.amazon.com/s3/)
- [Amazon Rekognition](https://aws.amazon.com/rekognition/) is run on each photo - this creates labels and tags
- Thumbnails are based on what Rekognition identifies in the photos
- Imports photos and metadata exported from Flickr

## Setup

    sudo apt install libpq-dev libexif-dev imagemagick

## Development

In separate terminals:

    bin/rails s
    bin/vite dev
    bundle exec sidekiq

Or use [overmind](https://github.com/DarthSim/overmind): `overmind s -N -f Procfile.dev`

## Starting Docker containers for system specs

    docker run -d \
        --name selenium-hub \
        -p 4442-4444:4442-4444 \
        --net grid \
        selenium/hub:latest

    docker run -d \
        --net grid \
        --shm-size="2g" \
        -e SE_EVENT_BUS_HOST=selenium-hub \
        -e SE_EVENT_BUS_PUBLISH_PORT=4442 \
        -e SE_EVENT_BUS_SUBSCRIBE_PORT=4443 \
        selenium/node-chrome:latest

Selenium Grid becomes available at http://localhost:4444/ui

**Note:** For the moment system specs are configured not to run from the [.rspec config file](.rspec).

## Versioning & Deployment

1. Update the [changelog](CHANGELOG.md)
2. Draft a new release on the [releases page](https://github.com/photonia-io/photonia/releases)
   - Create a tag with the prefix **release-** and the version, eg: **0.1.3** (resulting tag: **release-0.1.3**)
   - Prefix the release title with the release version, eg: **0.1.3 - An awesome release**
3. Publish the release

## Set up Docker host

The sitemap file will be persisted outside the container. The following commands should be run in the directory where you plan to run the container before the first deployment:

```
mkdir -p ./photonia-web/sitemap
touch ./photonia-web/sitemap/sitemap.xml.gz
chmod 777 ./photonia-web/sitemap/sitemap.xml.gz
```
