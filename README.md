# Photonia

A photo hosting service tailored to my needs.

## Technologies

[<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rails/rails-original-wordmark.svg" width="100"/>](https://rubyonrails.org/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/vuejs/vuejs-original.svg" width="100"/>](https://vuejs.org/) [<img src="https://raw.githubusercontent.com/devicons/devicon/develop/icons/vitejs/vitejs-original.svg" width="100"/>](https://vitejs.dev/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/graphql/graphql-plain.svg" width="100"/>](https://graphql.org/) [<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/amazonwebservices/amazonwebservices-original.svg" width="100"/>](https://aws.amazon.com/)

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
