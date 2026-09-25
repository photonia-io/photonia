# Photonia

[![Test coverage](https://codecov.io/gh/photonia-io/photonia/graph/badge.svg?token=kLLGDkhYew)](https://codecov.io/gh/photonia-io/photonia)
[![Licensed under the Apache License, Version 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](<[http://www.apache.org/licenses/LICENSE-2.0](https://github.com/photonia-io/photonia/blob/development/LICENSE)>)

A self hosted photo sharing webapp.

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

## Development

### Setup

    sudo apt install libpq-dev libexif-dev libvips

### Running the dev servers

In separate terminals:

    bin/rails s
    bin/vite dev
    bundle exec sidekiq

Or use [overmind](https://github.com/DarthSim/overmind): `overmind s -N -f Procfile.dev`

### System specs

System specs (`spec/system`) drive a headless Chrome through [Cuprite](https://github.com/rubycdp/cuprite) and run with the rest of the suite locally. On GitHub they run only on demand: Actions → "System specs" → Run workflow. They need Chrome or Chromium installed locally (`sudo apt install chromium`); set `BROWSER_PATH` if it isn't on the `PATH`.

## Versioning & Releases

1. Draft a new release on the [releases page](https://github.com/photonia-io/photonia/releases)
   - Create a tag with the prefix **release-** and the version, eg: **0.20.0** (resulting tag: **release-0.20.0**)
   - Prefix the release title with the release version, eg: **0.20.0 - An awesome release**
2. Publish the release

## Setting up the Docker host

The sitemap file will be persisted outside the container. The following commands should be run in the directory where you plan to run the container before the first deployment:

```
mkdir -p ./photonia-web/sitemap
touch ./photonia-web/sitemap/sitemap.xml.gz
chmod 777 ./photonia-web/sitemap/sitemap.xml.gz
```

## Deploying

Deploys go through [Kamal](https://kamal-deploy.org/). Secrets are pulled from 1Password, so you need the `op` CLI installed and signed in, with `$OP_ACCOUNT` exported in your shell.

```bash
cp config/deploy.production.template.yml config/deploy.production.yml   # first time only; fill in the real server
kamal deploy -d production
```

See the "Deployment" section in `CLAUDE.md` for how the config and secrets files fit together.
