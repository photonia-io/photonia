# Dockerfile - Development environment

FROM ruby:3.2.1

# versions
ENV NODE_VERSION=20.10.0
ENV NVM_VERSION=0.39.5
ENV YARN_VERSION=1.22.21

RUN apt-get update

# nodejs via nvm
RUN apt-get install -y curl
RUN curl --silent -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

# yarn via npm
RUN npm install --global yarn@${YARN_VERSION}

# other dependencies
RUN apt-get install -y postgresql-client
RUN apt-get install -y libexif-dev

# Create and switch to app directory
WORKDIR /usr/src/app

# bundle install
RUN gem install bundler:2.4.22
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install --jobs 5

# yarn install
COPY package.json .
COPY yarn.lock .
RUN yarn install

COPY . .
